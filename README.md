
# ARINC 429 IP Core

可靠稳定的航空电子数据总线解决方案

---

## 概述

天津深空智核科技有限公司开源的 **ARINC 429 IP核** 是专为航空电子系统设计的高性能协议控制器，完全兼容 ARINC 429 航空数据总线标准。该 IP 核提供硬件级协议处理能力，支持多通道配置，可轻松集成到 FPGA 和 ASIC 设计中。

### 核心优势：

- 🚀 简化航空电子系统开发  
- ⚡ 减少 CPU 开销，提升系统实时性  
- 🔒 提供硬件级数据完整性和可靠性  
- 🔧 高度可配置，适应不同应用场景  


---

## 特性

### 协议支持

- 完整实现 ARINC 429 规范
- 支持双速传输：12.5Kbps（低速）和 100Kbps（高速）
- 32 位字长，包含奇偶校验生成与验证

### 硬件架构

- 多通道支持：单 IP 核支持多路独立收发通道
- 双 FIFO 缓冲：独立的发送/接收 FIFO（深度可配置）
- 环回测试：支持本地环回和远程环回模式
- 智能中断：可配置的 FIFO 状态中断（空/满/几乎空/几乎满）

### 接口与控制

- Wishbone 总线接口（兼容多种微控制器）
- 精简寄存器映射（4 个 32 位寄存器）
- 可编程中断使能/屏蔽
- 硬件 FIFO 复位控制

### 性能指标

- 100MHz 系统时钟下处理能力达 3.2Mbps
- 单周期总线响应
- 边沿触发中断，响应延迟 <10ns

---

## 文件结构

| 文件 | 描述 |
|------|------|
|`a429/`|
|&nbsp;&nbsp;&nbsp;`a429_cs.v` | 命令状态寄存器模块（中断控制/寄存器管理） |
|&nbsp;&nbsp;&nbsp;`a429_rx.v` | ARINC 429 接收模块 |
|&nbsp;&nbsp;&nbsp;`a429_tx.v` | ARINC 429 发送模块 |
|&nbsp;&nbsp;&nbsp;`a429_top.v` | 单通道顶层模块 |
|&nbsp;&nbsp;&nbsp;`a429_top_multi.v` | 多通道顶层模块 |
|&nbsp;&nbsp;&nbsp;`bit_width_utils.v` | 位宽计算辅助模块 |
|&nbsp;&nbsp;&nbsp;`a429_rx_filter.v` | 接收滤波模块（抗噪声处理） |
|`doc/`|
| &nbsp;&nbsp;&nbsp;`CHANGELOG.md` | 更新日志文件 |
| &nbsp;&nbsp;&nbsp;`寄存器说明.md` | 详细寄存器说明文档 |
| `LICENSE` | 开源许可证 |
| `README.md` | 本文档
---

## 快速开始

### 单通道实例化

> 使用 `module A429_TOP` 实例化单通道配置：

```verilog
A429_TOP #(
  .CLOCK_KHZ(100000),     // 100MHz时钟
  .ENABLE_IRQ(1),         // 启用中断
  .TX_FIFO_DEEP(512),     // 发送FIFO深度
  .RX_FIFO_DEEP(512)      // 接收FIFO深度
) u_arinc429 (
  .rst_i(system_reset),
  .clk_i(system_clock),
  // Wishbone接口
  .cyc_i(wb_cyc),
  .stb_i(wb_stb),
  .adr_i(wb_addr[1:0]),
  .wnr_i(wb_we),
  .dat_i(wb_data_in),
  .dat_o(wb_data_out),
  .ack_o(wb_ack),
  // 中断和物理接口
  .irq_o(arinc_irq),
  .tx_slp_o(tx_speed),
  .tx_10_o({txA, txB}),
  .rx_ab_i({rxA, rxB})
);
```

---

## 寄存器映射

| 地址 | 名称 | 访问 | 描述 |
|------|------|------|------|
| 0x0 | FIFO | R/W | 数据寄存器（读写 FIFO） |
| 0x1 | CMD | R/W | 控制命令寄存器 |
| 0x2 | TXSTS | R/W | 发送状态（写操作清除中断） |
| 0x3 | RXSTS | R/W | 接收状态（写操作清除中断） |

> 详细寄存器说明见 [`寄存器说明.md`](./寄存器说明.md)

> C语言驱动程序：联系 sales@zzkkip.cn
---

## 配置选项

### 通用参数

> `CLOCK_KHZ` 必须是 **200kHz 的整数倍**，否则可能导致时序误差或协议不兼容。

| 参数 | 默认值 | 描述 |
|------|--------|------|
| `CLOCK_KHZ` | 100000 | 系统时钟频率 (KHz) |
| `ENABLE_IRQ` | 1 | 中断使能 (0:禁用, 1:启用) |

### 单通道参数

> 使用 `module A429_TOP` 配置以下参数：

| 参数 | 默认值 | 描述 |
|------|--------|------|
| `ENABLE_TX` | 1 | 发送通道使能 |
| `ENABLE_RX` | 1 | 接收通道使能 |
| `TX_FIFO_DEEP` | 514 | 发送 FIFO 深度 |
| `RX_FIFO_DEEP` | 514 | 接收 FIFO 深度 |

### 多通道参数

> 使用 `module A429_TOP_MULTI` 配置以下参数：

- `TX_NUM` 和 `RX_NUM` 的取值范围为 `0 ~ 32`，但要求 MAX(TX_NUM, RX_NUM) ≥ 2。

| 参数 | 默认值 | 描述 |
|------|--------|------|
| `TX_NUM` | 5 | 发送通道数 |
| `RX_NUM` | 8 | 接收通道数 |

---

## 应用场景

- 航空电子系统：飞行控制系统、导航系统  
- 工业控制：高可靠性数据通信  
- 测试设备：航电总线仿真与测试  
- 国防系统：军用航空电子平台  
- 卫星通信：星载数据处理系统  

---

## 公司其他航电总线IP产品

[天津深空智核](https://www.zzkkip.cn)提供完整的航电总线 IP 解决方案，包括但不限于：

| IP 协议 | 描述 |
|---------|------|
| MIL-STD-1394B | 高速军用数据总线 |
| MIL-STD-1553B | 军用航空数据总线 |
| FC-AE 系列 | 光纤通道航空电子环境 |
| FC-AE-1553 | 光纤通道 1553 协议 |
| FC-AE-ASM | 匿名订阅消息协议 |
| FC-AE-RDMA | 远程直接内存访问 |
| FC-AE SWITCH | 光纤通道交换机 |
| ARINC 664 (AFDX) | 航空电子全双工以太网 |
| ARINC 825 (CAN) | 航空电子 CAN 总线 |
| ARINC 818 | 航空电子视频协议 |
| UART | 通用异步收发器 |
| TTE | 确定性以太网 (Time-Triggered Ethernet) |
| TSN | 时间敏感网络 (Time-Sensitive Networking) |

---

## 版权与许可

```
Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
天津深空智核科技有限公司
https://www.zzkkip.cn
SPDX-License-Identifier: MIT
```

本 IP 核采用 MIT 许可证开源，允许自由使用、修改和分发，但需保留版权声明。

---

## 技术支持

如需商业支持、定制开发或完整 IP 解决方案，请联系：

- 📧 商务合作: [sales@zzkkip.cn](mailto:sales@zzkkip.cn)  
- ☎️ 技术支持: [liuyuan@zzkkip.cn](mailto:liuyuan@zzkkip.cn)  
- 🌐 官网: [https://www.zzkkip.cn](https://www.zzkkip.cn)  

---

让创新飞翔 - 天津深空智核助力下一代航空电子系统


## ⚠️ 使用限制 / Usage Restriction

本项目遵循 MIT 协议开源，但仅供中国大陆用户学习与非商业用途使用。严禁任何境外机构或个人使用、复制或传播本项目代码。如需授权，请联系作者。

> This project is licensed under the MIT License and intended **only for educational or non-commercial use within Mainland China**. Any use by foreign individuals or organizations is **strictly prohibited**. For licensing inquiries, please contact the author.


