# AWS Solutions Architect Associate (SAA) Hands-on Labs & Architecture Blueprints

Bộ lưu trữ mã nguồn, kiến trúc và các mẫu CloudFormation / Infrastructure as Code (IaC) phục vụ ôn tập thực hành chứng chỉ **AWS Certified Solutions Architect – Associate (SAA-C03)**.

---

## Danh Sách Các Bài Lab

| STT | Bài Lab | Dịch vụ chính | Mã nguồn & Tài liệu |
|:---:|:---|:---|:---:|
| **06** | **Triển khai ứng dụng FCAJ Management với Auto Scaling Group & ELB** | VPC, ALB, ASG (Manual, Scheduled, Dynamic, Predictive Scaling), Multi-AZ RDS MySQL, CloudWatch Metrics | [lab-06-autoscaling-predictive-scaling/](./lab-06-autoscaling-predictive-scaling/) |

---

## Hướng Dẫn Sử Dụng
Mỗi bài lab trong repository này đều bao gồm:
1. **Sơ đồ kiến trúc thực tế**: Thể hiện luồng mạng, phân chia subnet, load balancer và database.
2. **Template CloudFormation (`.yaml`)**: Dựng lại toàn bộ hệ thống bằng 1 lệnh duy nhất (`aws cloudformation create-stack`).
3. **Bộ script & dữ liệu mẫu**: Phục vụ mô phỏng tải, metric dự đoán hoặc kiểm thử tính năng.
4. **Ghi chú trọng tâm cho kỳ thi SAA**: Các bẫy đề thi, so sánh kiến trúc và Best Practices của AWS Well-Architected Framework.
