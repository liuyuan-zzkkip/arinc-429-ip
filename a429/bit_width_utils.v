// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Rx Module
// Revision   : v1.1
// =============================================================================
`ifndef BIT_WIDTH_UTILS
`define BIT_WIDTH_UTILS

// Address width calculator (log2 ceiling)
// Get number of bits needed to represent the input size
`define calc_aw(adr) (\
((adr) <= 1          ) ?   0 :((adr) <= 2          ) ?   1 :((adr) <= 4          ) ?   2 :((adr) <= 8          ) ?   3 :\
((adr) <= 16         ) ?   4 :((adr) <= 32         ) ?   5 :((adr) <= 64         ) ?   6 :((adr) <= 128        ) ?   7 :\
((adr) <= 256        ) ?   8 :((adr) <= 512        ) ?   9 :((adr) <= 1024       ) ?  10 :((adr) <= 2048       ) ?  11 :\
((adr) <= 4096       ) ?  12 :((adr) <= 8192       ) ?  13 :((adr) <= 16384      ) ?  14 :((adr) <= 32768      ) ?  15 :\
((adr) <= 65536      ) ?  16 :((adr) <= 131072     ) ?  17 :((adr) <= 262144     ) ?  18 :((adr) <= 524288     ) ?  19 :\
((adr) <= 1048576    ) ?  20 :((adr) <= 2097152    ) ?  21 :((adr) <= 4194304    ) ?  22 :((adr) <= 8388608    ) ?  23 :\
((adr) <= 16777216   ) ?  24 :((adr) <= 33554432   ) ?  25 :((adr) <= 67108864   ) ?  26 :((adr) <= 134217728  ) ?  27 :\
((adr) <= 268435456  ) ?  28 :((adr) <= 536870912  ) ?  29 :((adr) <= 1073741824 ) ?  30 :((adr) <= 2147483648 ) ?  31 :32)

// Counter width calculator (log2 ceiling with offset)
// Determine required bit width for counter with extra margin
`define calc_cw(cnt) (\
((cnt) < 1          ) ?   0 :((cnt) < 2          ) ?   1 :((cnt) < 4          ) ?   2 :((cnt) < 8          ) ?   3 :\
((cnt) < 16         ) ?   4 :((cnt) < 32         ) ?   5 :((cnt) < 64         ) ?   6 :((cnt) < 128        ) ?   7 :\
((cnt) < 256        ) ?   8 :((cnt) < 512        ) ?   9 :((cnt) < 1024       ) ?  10 :((cnt) < 2048       ) ?  11 :\
((cnt) < 4096       ) ?  12 :((cnt) < 8192       ) ?  13 :((cnt) < 16384      ) ?  14 :((cnt) < 32768      ) ?  15 :\
((cnt) < 65536      ) ?  16 :((cnt) < 131072     ) ?  17 :((cnt) < 262144     ) ?  18 :((cnt) < 524288     ) ?  19 :\
((cnt) < 1048576    ) ?  20 :((cnt) < 2097152    ) ?  21 :((cnt) < 4194304    ) ?  22 :((cnt) < 8388608    ) ?  23 :\
((cnt) < 16777216   ) ?  24 :((cnt) < 33554432   ) ?  25 :((cnt) < 67108864   ) ?  26 :((cnt) < 134217728  ) ?  27 :\
((cnt) < 268435456  ) ?  28 :((cnt) < 536870912  ) ?  29 :((cnt) < 1073741824 ) ?  30 :((cnt) < 2147483648 ) ?  31 :32)

`endif
