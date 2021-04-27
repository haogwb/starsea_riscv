//   Copyright [starsea] [star_sea_riscv,tsp162@163.com,2020/9]
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

module machine (
input               clk                          ,
input               rst_n                        ,
input       [31:0]  rs1_dat_ex                   ,
input       [31:0]  rd_dat                       ,
input               hazard_rs1                   ,
input       [31:0]  pc                           ,
input               system_ex                    ,
input       [ 2:0]  system_funct3_ex             ,
input       [11:0]  system_funct12_ex            ,
output  reg         ecall_bran_take              ,
output  reg         ebreak_bran_take             ,
output  reg         mret_bran_take               ,
output      [31:0]  trap_addr                    ,
output  reg         csrr_rd_en                   ,
output  reg [31:0]  csrr_rd_dat                  ,

input               store_misalign_exception     ,
input       [31:0]  store_misalign_addr          ,
input               load_misalign_exception      ,
input       [31:0]  load_misalign_addr           ,
input               misalign_exception           ,
output  reg         misalign_bran_take           ,
input               jalr_misalign_exception      ,
output  reg         jalr_misalign_bran_take      ,
input               j_misalign_exception         ,
output  reg         j_misalign_bran_take         ,
input               intr                         ,
output  reg         intr_bran_take
);

reg  [31:0] mtvec                        ;                             
reg  [31:0] mcause                       ;                             
reg  [31:0] mepc                         ;                             
reg  [31:0] mstatus                      ;                             
wire        mret_ex                      ;                             
reg  [31:0] mtval                        ;
reg  [31:0] mret_addr                    ;

wire [6:0]  system_funct7_ex = system_funct12_ex[11:5];

assign trap_addr = mret_bran_take ? mret_addr : mtvec;

reg intr_d;
always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        intr_d <= 0;
    else
        intr_d <= intr;


always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        ecall_bran_take <= 0;
    else if(system_ex & system_funct12_ex==0 &&system_funct3_ex==0)
        ecall_bran_take <= 1;
    else
        ecall_bran_take <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        ebreak_bran_take <= 0;
    else if(system_ex & system_funct12_ex==1 &&system_funct3_ex==0)
        ebreak_bran_take <= 1;
    else
        ebreak_bran_take <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mret_addr <= 0;
    else if(system_ex & system_funct7_ex=='h18 &&system_funct3_ex==0)
        mret_addr <= mepc;


always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mret_bran_take <= 0;
    else if(system_ex & system_funct7_ex=='h18 &&system_funct3_ex==0)
        mret_bran_take <= 1;
    else
        mret_bran_take <= 0;

reg [31:0] pc_ex;
always@(posedge clk or negedge rst_n)
    if(~rst_n)   pc_ex <= 0;
    else         pc_ex <= pc;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mcause <= 32'h0;//20210406  //32'hffffffff;
    else if(system_ex & system_funct12_ex==0 &&system_funct3_ex==0)
        mcause <= 11;
    else if(system_ex & system_funct12_ex==1 &&system_funct3_ex==0)//ebreak
        mcause <= 3;
    else if(load_misalign_exception)
        mcause <= 4;
    else if(store_misalign_exception)
        mcause <= 6;
    else if(misalign_exception)
        mcause <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        csrr_rd_en <= 0;
    else if(system_ex &&(system_funct3_ex==2 || system_funct3_ex==1
                                             || system_funct3_ex==7 )) //1: csrrw, 7:csrci
        csrr_rd_en <= 1;
    else
        csrr_rd_en <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        csrr_rd_dat <= 0;
    else if(system_ex &&system_funct3_ex==2)
        case (system_funct12_ex)
        12'h300 :  csrr_rd_dat <= mstatus;
        12'h305 :  csrr_rd_dat <= mtvec;
        12'h341 :  csrr_rd_dat <= mepc;
        12'h342 :  csrr_rd_dat <= mcause;
        12'h343 :  csrr_rd_dat <= mtval;
        default:   csrr_rd_dat <= 0;
        endcase
//    else if(system_ex &&system_funct3_ex==1)
//        csrr_rd_dat <= mtvec;
    else
        csrr_rd_dat <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mtvec <= 4;
    else if(system_ex && (system_funct3_ex==1) && system_funct12_ex == 'h305)
        mtvec <= hazard_rs1 ? rd_dat : rs1_dat_ex;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mstatus <= 0;
    else if(system_ex && (system_funct3_ex==1) && system_funct12_ex == 'h300)
        mstatus <= hazard_rs1 ? rd_dat : rs1_dat_ex;

wire MIE = mstatus[3];//global interrupt enable bits

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mepc <= 0;
    else if(system_ex & system_funct12_ex==0 &&system_funct3_ex==0)//ecal
        mepc <= pc_ex;
    else if(system_ex & system_funct12_ex==1 &&system_funct3_ex==0)//ebreak
        mepc <= pc_ex;
    else if(system_ex && (system_funct3_ex==1) && system_funct12_ex == 'h341)
        mepc <= hazard_rs1 ? rd_dat : rs1_dat_ex;
    else if (store_misalign_exception | load_misalign_exception | misalign_exception)
        mepc <= pc_ex;
    else if(intr & ~intr_d & MIE)
        mepc <= pc_ex;

reg j_misalign_exception_ex;
always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        j_misalign_exception_ex <= 0;
    else
        j_misalign_exception_ex <= j_misalign_exception;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        j_misalign_bran_take <= 0;
    else if(j_misalign_exception_ex)
        j_misalign_bran_take <= 1;
    else
        j_misalign_bran_take <= 0;


always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        mtval <= 0;
    else if (misalign_exception|jalr_misalign_exception | j_misalign_exception_ex)
        mtval <= pc;
    else if (load_misalign_exception)
        mtval <= load_misalign_addr;
    else if (store_misalign_exception)
        mtval <= store_misalign_addr;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        jalr_misalign_bran_take <= 0;
    else if(jalr_misalign_exception)
        jalr_misalign_bran_take <= 1;
    else
        jalr_misalign_bran_take <= 0;

always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        misalign_bran_take <= 0;
    else if(misalign_exception | load_misalign_exception| store_misalign_exception)
        misalign_bran_take <= 1;
    else
        misalign_bran_take <= 0;
always@(posedge clk or negedge rst_n)
    if(~rst_n) 
        intr_bran_take <= 0;
    else if(intr & ~intr_d & MIE)
        intr_bran_take <= 1;
    else
        intr_bran_take <= 0;
endmodule
