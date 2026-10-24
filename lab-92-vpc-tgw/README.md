# Lab 92: VPC Components Deep Dive & Multi-VPC Transit Gateway Hybrid Architecture

Tài liệu hướng dẫn triển khai, cấu trúc kiến trúc và ôn tập chứng chỉ AWS Solutions Architect Associate (SAA) / AWS Certified Advanced Networking - Specialty (ANS) cho bài thực hành **VPC Components Deep Dive**.

---

## 1. Sơ đồ kiến trúc (Architecture Overview)

Hệ thống được thiết kế theo mô hình **Multi-VPC Enterprise Hub-and-Spoke / Hybrid Cloud** chuẩn AWS với tổng dải mạng `10.0.0.0/11`:

![Subnet Diagram](images/hybrid-subnets-diagram.png)

### Bảng phân bổ mạng & VPC (IP Addressing Plan):

| Tên VPC (`lab92-*`) | Dải CIDR | Mục đích | Số Subnet | Route Tables | Gateways / Connectors |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`lab92-np1`** | `10.16.0.0/16` | Môi trường Non-Production (Development) | 6 (2 Public, 2 Private, 2 Attach) | 3 Custom RTs | TGW Attachment (`lab92-tgw-attach-np1`) |
| **`lab92-np2`** | `10.17.0.0/16` | Môi trường Non-Production (Testing/QA) | 6 (2 Public, 2 Private, 2 Attach) | 3 Custom RTs | TGW Attachment (`lab92-tgw-attach-np2`) |
| **`lab92-p1`** | `10.8.0.0/16` | Môi trường Production | 6 (2 Public, 2 Private, 2 Attach) | 3 Custom RTs | TGW Attachment (`lab92-tgw-attach-p1`) |
| **`lab92-dcs`** | `10.0.0.0/16` | Datacenter Shared Services (Central Egress) | 6 (2 Public, 2 Private, 2 Attach) | 3 Custom RTs | IGW (`lab92-igw-dcs`) + NAT GW + TGW Attachment |
| **`lab92-dc`** | `10.4.0.0/16` | Simulated On-Premises Datacenter | 6 (2 Public, 2 Private, 2 Attach) | 3 Custom RTs | IGW (`lab92-igw-dc`) + TGW Attachment |

---

## 2. Quy chuẩn đặt tên tài nguyên (`lab92-*`)

Toàn bộ tài nguyên được chuẩn hóa theo định dạng nhất quán:

- **Transit Gateway**: `lab92-tgw`
- **VPC Attachments**: `lab92-tgw-attach-dcs`, `lab92-tgw-attach-np1`, `lab92-tgw-attach-np2`, `lab92-tgw-attach-p1`, `lab92-tgw-attach-dc`
- **VPC**: `lab92-np1`, `lab92-np2`, `lab92-p1`, `lab92-dcs`, `lab92-dc`
- **Subnet**: `lab92-sub-[public|private]-[vpc]-[purpose]-az-[a|b]`
  - Ví dụ: `lab92-sub-public-np1-az-a`, `lab92-sub-private-np1-az-a`, `lab92-sub-private-np1-attach-az-a`
- **Route Table**: `lab92-rt-[public|private|attach]-[vpc]`
  - Ví dụ: `lab92-rt-public-np1`, `lab92-rt-private-np1`, `lab92-rt-attach-np1`
- **Gateways**:
  - Internet Gateway: `lab92-igw-dcs`, `lab92-igw-dc`
  - NAT Gateway: `lab92-nat-sub-public-dcs`
  - Elastic IP: `lab92-eip-dcs`
- **EC2 Test Servers (quản lý qua SSM Session Manager)**:
  - `lab92-ec2-dev` (NP1 - `10.16.10.x`)
  - `lab92-ec2-test` (NP2 - `10.17.10.x`)
  - `lab92-ec2-prod` (P1 - `10.8.10.x`)
  - `lab92-ec2-dcs` (DCS - `10.0.10.x`)
  - `lab92-ec2-dc` (DC - `10.4.10.x`)

---

## 3. Kiến trúc Centralized Egress & Định tuyến Transit Gateway

1. **Centralized Internet Egress**:
   - Tất cả Private Subnet ở các Spoke VPC (`np1`, `np2`, `p1`, `dc`) đều trỏ route `0.0.0.0/0` về `lab92-tgw`.
   - Trên Transit Gateway Route Table: Route `0.0.0.0/0` trỏ đến attachment của **DCS VPC** (`lab92-tgw-attach-dcs`).
   - Trên Route Table của Subnet Attach DCS (`lab92-rt-attach-dcs`): Định tuyến `0.0.0.0/0` sang **NAT Gateway** ở Public Subnet DCS.
   - Nhờ đó, tất cả máy chủ trong Private Subnet đều có Internet egress tập trung qua 1 NAT Gateway duy nhất để tải package và kết nối AWS Systems Manager.
2. **Return Traffic**:
   - Route Table Public & Private của DCS chứa route `10.0.0.0/11` trỏ ngược lại `lab92-tgw` để trả gói tin cho các Spoke VPCs.

---

## 4. Giải thích bài lab: Mục 4.2 Cisco CSR Access & VPN

### Mục tiêu của phần 4.2:
- Trong mô hình Hybrid Cloud của bài Lab, VPC `lab92-dc` (`10.4.0.0/16`) đóng vai trò là **Datacenter tại chỗ (On-Premises)**.
- Router ảo **Cisco Cloud Services Router (CSR) 1000V** được triển khai tại Datacenter này để thiết lập kết nối **Site-to-Site IPsec VPN** tới AWS Transit Gateway.
- Nhiệm vụ của mục 4.2 là:
  1. Đăng nhập vào thiết bị Cisco CSR qua giao diện dòng lệnh SSH (`ssh ec2-user@<cisco-ip>`).
  2. Kiểm tra cấu hình mạng ban đầu của router bằng các lệnh Cisco IOS:
     - `show ip interface brief`: Kiểm tra trạng thái các interface mạng (GigabitEthernet1 kết nối mạng Datacenter, Tunnel1/Tunnel2 kết nối VPN).
     - `show ip route`: Kiểm tra bảng định tuyến tại On-Premises.
  3. Chuẩn bị cho phần cấu hình BGP và VPN tunnels ở các bước tiếp theo (4.3 và 4.4).

### Giải pháp thay thế AWS Cloud9:
- AWS đã ngừng hỗ trợ dịch vụ Cloud9 cho tài khoản mới.
- Thay vì Cloud9, ta sử dụng **AWS Systems Manager (SSM) Session Manager** với plugin trên máy cá nhân hoặc script `./connect.sh`:
  - Hoàn toàn miễn phí, bảo mật (không cần mở cổng SSH 22, không cần Public IP).
  - Tích hợp sẵn trong CloudFormation template thông qua IAM Role `AmazonSSMManagedInstanceCore`.

---

## 5. Hướng dẫn kết nối kiểm thử nhanh bằng `connect.sh`

File tiện ích `connect.sh` cho phép kết nối trực tiếp vào terminal của bất kỳ EC2 server nào chỉ bằng 1 dòng lệnh:

```bash
# Kết nối vào Dev instance (NP1)
./connect.sh dev

# Kết nối vào Test instance (NP2)
./connect.sh test

# Kết nối vào Production instance (P1)
./connect.sh prod

# Kết nối vào DCS Shared Services instance
./connect.sh dcs

# Kết nối vào Datacenter instance (DC)
./connect.sh dc
```

Sau khi kết nối vào `lab92-ec2-dev`, bạn có thể kiểm tra kết nối liên VPC qua Transit Gateway:
```bash
# Ping sang máy test ở NP2 (10.17.x.x)
ping -c 3 10.17.10.xxx

# Ping sang máy prod ở P1 (10.8.x.x)
ping -c 3 10.8.10.xxx

# Kiểm tra truy cập Internet qua Centralized NAT Gateway
curl -I https://aws.amazon.com
```

---

## 6. Cách triển khai bằng 1-Click CloudFormation

### Triển khai qua AWS CLI:
```bash
aws cloudformation create-stack \
  --stack-name lab92-vpc-tgw-stack \
  --template-body file://cloudformation/lab92-tgw-vpcs.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Triển khai qua AWS Console:
1. Đăng nhập AWS Console -> chọn Region **N. Virginia (`us-east-1`)**.
2. Mở dịch vụ **CloudFormation** -> Click **Create stack** (With new resources).
3. Chọn **Upload a template file** -> Chọn file `cloudformation/lab92-tgw-vpcs.yaml`.
4. Nhập Stack Name: `lab92-vpc-tgw-stack`.
5. Đánh dấu tích xác nhận: `I acknowledge that AWS CloudFormation might create IAM resources with custom names`.
6. Click **Submit** và đợi ~3-5 phút để hệ thống tự động khởi tạo toàn bộ hạ tầng.

---

## 7. Dọn dẹp tài nguyên (Xóa stack để tiết kiệm 100% chi phí)

Khi kết thúc học tập hoặc thực hành, xóa sạch toàn bộ hệ thống bằng lệnh:
```bash
aws cloudformation delete-stack --stack-name lab92-vpc-tgw-stack --region us-east-1
```
Lệnh trên sẽ tự động xóa sạch 5 VPCs, 30 Subnets, 20 Route Tables, Transit Gateway, NAT Gateway, Elastic IP và 5 EC2 instances mà không để lại bất kỳ chi phí phát sinh nào.
