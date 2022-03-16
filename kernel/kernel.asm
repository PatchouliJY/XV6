
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	cf478793          	addi	a5,a5,-780 # 80005d50 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e9e78793          	addi	a5,a5,-354 # 80000f44 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b8a080e7          	jalr	-1142(ra) # 80000c96 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	45c080e7          	jalr	1116(ra) # 80002582 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	830080e7          	jalr	-2000(ra) # 80000966 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bfc080e7          	jalr	-1028(ra) # 80000d4a <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	af8080e7          	jalr	-1288(ra) # 80000c96 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	896080e7          	jalr	-1898(ra) # 80001a64 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	0ec080e7          	jalr	236(ra) # 800022ca <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	312080e7          	jalr	786(ra) # 8000252c <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	b14080e7          	jalr	-1260(ra) # 80000d4a <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	afe080e7          	jalr	-1282(ra) # 80000d4a <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	5ea080e7          	jalr	1514(ra) # 80000880 <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5d8080e7          	jalr	1496(ra) # 80000880 <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5cc080e7          	jalr	1484(ra) # 80000880 <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5c2080e7          	jalr	1474(ra) # 80000880 <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	9b8080e7          	jalr	-1608(ra) # 80000c96 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	2dc080e7          	jalr	732(ra) # 800025d8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a3e080e7          	jalr	-1474(ra) # 80000d4a <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	000080e7          	jalr	ra # 80002450 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	794080e7          	jalr	1940(ra) # 80000c06 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	3b6080e7          	jalr	950(ra) # 80000830 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	f2e78793          	addi	a5,a5,-210 # 800223b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000552:	00011497          	auipc	s1,0x11
    80000556:	38648493          	addi	s1,s1,902 # 800118d8 <pr>
    8000055a:	00008597          	auipc	a1,0x8
    8000055e:	abe58593          	addi	a1,a1,-1346 # 80008018 <etext+0x18>
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	6a2080e7          	jalr	1698(ra) # 80000c06 <initlock>
  pr.locking = 1;
    8000056c:	4785                	li	a5,1
    8000056e:	cc9c                	sw	a5,24(s1)
}
    80000570:	60e2                	ld	ra,24(sp)
    80000572:	6442                	ld	s0,16(sp)
    80000574:	64a2                	ld	s1,8(sp)
    80000576:	6105                	addi	sp,sp,32
    80000578:	8082                	ret

000000008000057a <backtrace>:

void
backtrace(void)
{
    8000057a:	7139                	addi	sp,sp,-64
    8000057c:	fc06                	sd	ra,56(sp)
    8000057e:	f822                	sd	s0,48(sp)
    80000580:	f426                	sd	s1,40(sp)
    80000582:	f04a                	sd	s2,32(sp)
    80000584:	ec4e                	sd	s3,24(sp)
    80000586:	e852                	sd	s4,16(sp)
    80000588:	e456                	sd	s5,8(sp)
    8000058a:	0080                	addi	s0,sp,64
  printf("backtrace:\n");
    8000058c:	00008517          	auipc	a0,0x8
    80000590:	a9450513          	addi	a0,a0,-1388 # 80008020 <etext+0x20>
    80000594:	00000097          	auipc	ra,0x0
    80000598:	0b6080e7          	jalr	182(ra) # 8000064a <printf>

// read frame pointer
static inline uint64
r_fp() {
  uint64 x;
  asm volatile("mv %0, s0" : "=r" (x));
    8000059c:	84a2                	mv	s1,s0
  uint64 fp = r_fp();
  while(PGROUNDUP(fp) - PGROUNDDOWN(fp) == PGSIZE) {
    8000059e:	6685                	lui	a3,0x1
    800005a0:	fff68793          	addi	a5,a3,-1 # fff <_entry-0x7ffff001>
    800005a4:	97a6                	add	a5,a5,s1
    800005a6:	777d                	lui	a4,0xfffff
    800005a8:	8ff9                	and	a5,a5,a4
    800005aa:	8f65                	and	a4,a4,s1
    800005ac:	8f99                	sub	a5,a5,a4
    800005ae:	02d79c63          	bne	a5,a3,800005e6 <backtrace+0x6c>
    uint64 rt_addr = *((uint64*)(fp - 8));
    printf("%p\n", rt_addr);
    800005b2:	00008a97          	auipc	s5,0x8
    800005b6:	a7ea8a93          	addi	s5,s5,-1410 # 80008030 <etext+0x30>
  while(PGROUNDUP(fp) - PGROUNDDOWN(fp) == PGSIZE) {
    800005ba:	6985                	lui	s3,0x1
    800005bc:	fff98a13          	addi	s4,s3,-1 # fff <_entry-0x7ffff001>
    800005c0:	797d                	lui	s2,0xfffff
    printf("%p\n", rt_addr);
    800005c2:	ff84b583          	ld	a1,-8(s1)
    800005c6:	8556                	mv	a0,s5
    800005c8:	00000097          	auipc	ra,0x0
    800005cc:	082080e7          	jalr	130(ra) # 8000064a <printf>
    fp = *((uint64*) (fp - 16));
    800005d0:	ff04b483          	ld	s1,-16(s1)
  while(PGROUNDUP(fp) - PGROUNDDOWN(fp) == PGSIZE) {
    800005d4:	014487b3          	add	a5,s1,s4
    800005d8:	0127f7b3          	and	a5,a5,s2
    800005dc:	0124f733          	and	a4,s1,s2
    800005e0:	8f99                	sub	a5,a5,a4
    800005e2:	ff3780e3          	beq	a5,s3,800005c2 <backtrace+0x48>
  }
    800005e6:	70e2                	ld	ra,56(sp)
    800005e8:	7442                	ld	s0,48(sp)
    800005ea:	74a2                	ld	s1,40(sp)
    800005ec:	7902                	ld	s2,32(sp)
    800005ee:	69e2                	ld	s3,24(sp)
    800005f0:	6a42                	ld	s4,16(sp)
    800005f2:	6aa2                	ld	s5,8(sp)
    800005f4:	6121                	addi	sp,sp,64
    800005f6:	8082                	ret

00000000800005f8 <panic>:
{
    800005f8:	1101                	addi	sp,sp,-32
    800005fa:	ec06                	sd	ra,24(sp)
    800005fc:	e822                	sd	s0,16(sp)
    800005fe:	e426                	sd	s1,8(sp)
    80000600:	1000                	addi	s0,sp,32
    80000602:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000604:	00011797          	auipc	a5,0x11
    80000608:	2e07a623          	sw	zero,748(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a2c50513          	addi	a0,a0,-1492 # 80008038 <etext+0x38>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	036080e7          	jalr	54(ra) # 8000064a <printf>
  printf(s);
    8000061c:	8526                	mv	a0,s1
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	02c080e7          	jalr	44(ra) # 8000064a <printf>
  printf("\n");
    80000626:	00008517          	auipc	a0,0x8
    8000062a:	aba50513          	addi	a0,a0,-1350 # 800080e0 <digits+0x88>
    8000062e:	00000097          	auipc	ra,0x0
    80000632:	01c080e7          	jalr	28(ra) # 8000064a <printf>
  backtrace();
    80000636:	00000097          	auipc	ra,0x0
    8000063a:	f44080e7          	jalr	-188(ra) # 8000057a <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    8000063e:	4785                	li	a5,1
    80000640:	00009717          	auipc	a4,0x9
    80000644:	9cf72023          	sw	a5,-1600(a4) # 80009000 <panicked>
  for(;;)
    80000648:	a001                	j	80000648 <panic+0x50>

000000008000064a <printf>:
{
    8000064a:	7131                	addi	sp,sp,-192
    8000064c:	fc86                	sd	ra,120(sp)
    8000064e:	f8a2                	sd	s0,112(sp)
    80000650:	f4a6                	sd	s1,104(sp)
    80000652:	f0ca                	sd	s2,96(sp)
    80000654:	ecce                	sd	s3,88(sp)
    80000656:	e8d2                	sd	s4,80(sp)
    80000658:	e4d6                	sd	s5,72(sp)
    8000065a:	e0da                	sd	s6,64(sp)
    8000065c:	fc5e                	sd	s7,56(sp)
    8000065e:	f862                	sd	s8,48(sp)
    80000660:	f466                	sd	s9,40(sp)
    80000662:	f06a                	sd	s10,32(sp)
    80000664:	ec6e                	sd	s11,24(sp)
    80000666:	0100                	addi	s0,sp,128
    80000668:	8a2a                	mv	s4,a0
    8000066a:	e40c                	sd	a1,8(s0)
    8000066c:	e810                	sd	a2,16(s0)
    8000066e:	ec14                	sd	a3,24(s0)
    80000670:	f018                	sd	a4,32(s0)
    80000672:	f41c                	sd	a5,40(s0)
    80000674:	03043823          	sd	a6,48(s0)
    80000678:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000067c:	00011d97          	auipc	s11,0x11
    80000680:	274dad83          	lw	s11,628(s11) # 800118f0 <pr+0x18>
  if(locking)
    80000684:	020d9b63          	bnez	s11,800006ba <printf+0x70>
  if (fmt == 0)
    80000688:	040a0263          	beqz	s4,800006cc <printf+0x82>
  va_start(ap, fmt);
    8000068c:	00840793          	addi	a5,s0,8
    80000690:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000694:	000a4503          	lbu	a0,0(s4)
    80000698:	16050263          	beqz	a0,800007fc <printf+0x1b2>
    8000069c:	4481                	li	s1,0
    if(c != '%'){
    8000069e:	02500a93          	li	s5,37
    switch(c){
    800006a2:	07000b13          	li	s6,112
  consputc('x');
    800006a6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006a8:	00008b97          	auipc	s7,0x8
    800006ac:	9b0b8b93          	addi	s7,s7,-1616 # 80008058 <digits>
    switch(c){
    800006b0:	07300c93          	li	s9,115
    800006b4:	06400c13          	li	s8,100
    800006b8:	a82d                	j	800006f2 <printf+0xa8>
    acquire(&pr.lock);
    800006ba:	00011517          	auipc	a0,0x11
    800006be:	21e50513          	addi	a0,a0,542 # 800118d8 <pr>
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	5d4080e7          	jalr	1492(ra) # 80000c96 <acquire>
    800006ca:	bf7d                	j	80000688 <printf+0x3e>
    panic("null fmt");
    800006cc:	00008517          	auipc	a0,0x8
    800006d0:	97c50513          	addi	a0,a0,-1668 # 80008048 <etext+0x48>
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	f24080e7          	jalr	-220(ra) # 800005f8 <panic>
      consputc(c);
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	baa080e7          	jalr	-1110(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006e4:	2485                	addiw	s1,s1,1
    800006e6:	009a07b3          	add	a5,s4,s1
    800006ea:	0007c503          	lbu	a0,0(a5)
    800006ee:	10050763          	beqz	a0,800007fc <printf+0x1b2>
    if(c != '%'){
    800006f2:	ff5515e3          	bne	a0,s5,800006dc <printf+0x92>
    c = fmt[++i] & 0xff;
    800006f6:	2485                	addiw	s1,s1,1
    800006f8:	009a07b3          	add	a5,s4,s1
    800006fc:	0007c783          	lbu	a5,0(a5)
    80000700:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000704:	cfe5                	beqz	a5,800007fc <printf+0x1b2>
    switch(c){
    80000706:	05678a63          	beq	a5,s6,8000075a <printf+0x110>
    8000070a:	02fb7663          	bgeu	s6,a5,80000736 <printf+0xec>
    8000070e:	09978963          	beq	a5,s9,800007a0 <printf+0x156>
    80000712:	07800713          	li	a4,120
    80000716:	0ce79863          	bne	a5,a4,800007e6 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000071a:	f8843783          	ld	a5,-120(s0)
    8000071e:	00878713          	addi	a4,a5,8
    80000722:	f8e43423          	sd	a4,-120(s0)
    80000726:	4605                	li	a2,1
    80000728:	85ea                	mv	a1,s10
    8000072a:	4388                	lw	a0,0(a5)
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	d7a080e7          	jalr	-646(ra) # 800004a6 <printint>
      break;
    80000734:	bf45                	j	800006e4 <printf+0x9a>
    switch(c){
    80000736:	0b578263          	beq	a5,s5,800007da <printf+0x190>
    8000073a:	0b879663          	bne	a5,s8,800007e6 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000073e:	f8843783          	ld	a5,-120(s0)
    80000742:	00878713          	addi	a4,a5,8
    80000746:	f8e43423          	sd	a4,-120(s0)
    8000074a:	4605                	li	a2,1
    8000074c:	45a9                	li	a1,10
    8000074e:	4388                	lw	a0,0(a5)
    80000750:	00000097          	auipc	ra,0x0
    80000754:	d56080e7          	jalr	-682(ra) # 800004a6 <printint>
      break;
    80000758:	b771                	j	800006e4 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000075a:	f8843783          	ld	a5,-120(s0)
    8000075e:	00878713          	addi	a4,a5,8
    80000762:	f8e43423          	sd	a4,-120(s0)
    80000766:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000076a:	03000513          	li	a0,48
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	b18080e7          	jalr	-1256(ra) # 80000286 <consputc>
  consputc('x');
    80000776:	07800513          	li	a0,120
    8000077a:	00000097          	auipc	ra,0x0
    8000077e:	b0c080e7          	jalr	-1268(ra) # 80000286 <consputc>
    80000782:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000784:	03c9d793          	srli	a5,s3,0x3c
    80000788:	97de                	add	a5,a5,s7
    8000078a:	0007c503          	lbu	a0,0(a5)
    8000078e:	00000097          	auipc	ra,0x0
    80000792:	af8080e7          	jalr	-1288(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000796:	0992                	slli	s3,s3,0x4
    80000798:	397d                	addiw	s2,s2,-1
    8000079a:	fe0915e3          	bnez	s2,80000784 <printf+0x13a>
    8000079e:	b799                	j	800006e4 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800007a0:	f8843783          	ld	a5,-120(s0)
    800007a4:	00878713          	addi	a4,a5,8
    800007a8:	f8e43423          	sd	a4,-120(s0)
    800007ac:	0007b903          	ld	s2,0(a5)
    800007b0:	00090e63          	beqz	s2,800007cc <printf+0x182>
      for(; *s; s++)
    800007b4:	00094503          	lbu	a0,0(s2) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800007b8:	d515                	beqz	a0,800006e4 <printf+0x9a>
        consputc(*s);
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	acc080e7          	jalr	-1332(ra) # 80000286 <consputc>
      for(; *s; s++)
    800007c2:	0905                	addi	s2,s2,1
    800007c4:	00094503          	lbu	a0,0(s2)
    800007c8:	f96d                	bnez	a0,800007ba <printf+0x170>
    800007ca:	bf29                	j	800006e4 <printf+0x9a>
        s = "(null)";
    800007cc:	00008917          	auipc	s2,0x8
    800007d0:	87490913          	addi	s2,s2,-1932 # 80008040 <etext+0x40>
      for(; *s; s++)
    800007d4:	02800513          	li	a0,40
    800007d8:	b7cd                	j	800007ba <printf+0x170>
      consputc('%');
    800007da:	8556                	mv	a0,s5
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	aaa080e7          	jalr	-1366(ra) # 80000286 <consputc>
      break;
    800007e4:	b701                	j	800006e4 <printf+0x9a>
      consputc('%');
    800007e6:	8556                	mv	a0,s5
    800007e8:	00000097          	auipc	ra,0x0
    800007ec:	a9e080e7          	jalr	-1378(ra) # 80000286 <consputc>
      consputc(c);
    800007f0:	854a                	mv	a0,s2
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	a94080e7          	jalr	-1388(ra) # 80000286 <consputc>
      break;
    800007fa:	b5ed                	j	800006e4 <printf+0x9a>
  if(locking)
    800007fc:	020d9163          	bnez	s11,8000081e <printf+0x1d4>
}
    80000800:	70e6                	ld	ra,120(sp)
    80000802:	7446                	ld	s0,112(sp)
    80000804:	74a6                	ld	s1,104(sp)
    80000806:	7906                	ld	s2,96(sp)
    80000808:	69e6                	ld	s3,88(sp)
    8000080a:	6a46                	ld	s4,80(sp)
    8000080c:	6aa6                	ld	s5,72(sp)
    8000080e:	6b06                	ld	s6,64(sp)
    80000810:	7be2                	ld	s7,56(sp)
    80000812:	7c42                	ld	s8,48(sp)
    80000814:	7ca2                	ld	s9,40(sp)
    80000816:	7d02                	ld	s10,32(sp)
    80000818:	6de2                	ld	s11,24(sp)
    8000081a:	6129                	addi	sp,sp,192
    8000081c:	8082                	ret
    release(&pr.lock);
    8000081e:	00011517          	auipc	a0,0x11
    80000822:	0ba50513          	addi	a0,a0,186 # 800118d8 <pr>
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	524080e7          	jalr	1316(ra) # 80000d4a <release>
}
    8000082e:	bfc9                	j	80000800 <printf+0x1b6>

0000000080000830 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000830:	1141                	addi	sp,sp,-16
    80000832:	e406                	sd	ra,8(sp)
    80000834:	e022                	sd	s0,0(sp)
    80000836:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000838:	100007b7          	lui	a5,0x10000
    8000083c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000840:	f8000713          	li	a4,-128
    80000844:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000848:	470d                	li	a4,3
    8000084a:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000084e:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000852:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000856:	469d                	li	a3,7
    80000858:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000085c:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000860:	00008597          	auipc	a1,0x8
    80000864:	81058593          	addi	a1,a1,-2032 # 80008070 <digits+0x18>
    80000868:	00011517          	auipc	a0,0x11
    8000086c:	09050513          	addi	a0,a0,144 # 800118f8 <uart_tx_lock>
    80000870:	00000097          	auipc	ra,0x0
    80000874:	396080e7          	jalr	918(ra) # 80000c06 <initlock>
}
    80000878:	60a2                	ld	ra,8(sp)
    8000087a:	6402                	ld	s0,0(sp)
    8000087c:	0141                	addi	sp,sp,16
    8000087e:	8082                	ret

0000000080000880 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000880:	1101                	addi	sp,sp,-32
    80000882:	ec06                	sd	ra,24(sp)
    80000884:	e822                	sd	s0,16(sp)
    80000886:	e426                	sd	s1,8(sp)
    80000888:	1000                	addi	s0,sp,32
    8000088a:	84aa                	mv	s1,a0
  push_off();
    8000088c:	00000097          	auipc	ra,0x0
    80000890:	3be080e7          	jalr	958(ra) # 80000c4a <push_off>

  if(panicked){
    80000894:	00008797          	auipc	a5,0x8
    80000898:	76c7a783          	lw	a5,1900(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000089c:	10000737          	lui	a4,0x10000
  if(panicked){
    800008a0:	c391                	beqz	a5,800008a4 <uartputc_sync+0x24>
    for(;;)
    800008a2:	a001                	j	800008a2 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008a4:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800008a8:	0ff7f793          	andi	a5,a5,255
    800008ac:	0207f793          	andi	a5,a5,32
    800008b0:	dbf5                	beqz	a5,800008a4 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    800008b2:	0ff4f793          	andi	a5,s1,255
    800008b6:	10000737          	lui	a4,0x10000
    800008ba:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800008be:	00000097          	auipc	ra,0x0
    800008c2:	42c080e7          	jalr	1068(ra) # 80000cea <pop_off>
}
    800008c6:	60e2                	ld	ra,24(sp)
    800008c8:	6442                	ld	s0,16(sp)
    800008ca:	64a2                	ld	s1,8(sp)
    800008cc:	6105                	addi	sp,sp,32
    800008ce:	8082                	ret

00000000800008d0 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008d0:	00008797          	auipc	a5,0x8
    800008d4:	7347a783          	lw	a5,1844(a5) # 80009004 <uart_tx_r>
    800008d8:	00008717          	auipc	a4,0x8
    800008dc:	73072703          	lw	a4,1840(a4) # 80009008 <uart_tx_w>
    800008e0:	08f70263          	beq	a4,a5,80000964 <uartstart+0x94>
{
    800008e4:	7139                	addi	sp,sp,-64
    800008e6:	fc06                	sd	ra,56(sp)
    800008e8:	f822                	sd	s0,48(sp)
    800008ea:	f426                	sd	s1,40(sp)
    800008ec:	f04a                	sd	s2,32(sp)
    800008ee:	ec4e                	sd	s3,24(sp)
    800008f0:	e852                	sd	s4,16(sp)
    800008f2:	e456                	sd	s5,8(sp)
    800008f4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f6:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008fa:	00011a17          	auipc	s4,0x11
    800008fe:	ffea0a13          	addi	s4,s4,-2 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000902:	00008497          	auipc	s1,0x8
    80000906:	70248493          	addi	s1,s1,1794 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000090a:	00008997          	auipc	s3,0x8
    8000090e:	6fe98993          	addi	s3,s3,1790 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000912:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000916:	0ff77713          	andi	a4,a4,255
    8000091a:	02077713          	andi	a4,a4,32
    8000091e:	cb15                	beqz	a4,80000952 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    80000920:	00fa0733          	add	a4,s4,a5
    80000924:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000928:	2785                	addiw	a5,a5,1
    8000092a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000092e:	01b7571b          	srliw	a4,a4,0x1b
    80000932:	9fb9                	addw	a5,a5,a4
    80000934:	8bfd                	andi	a5,a5,31
    80000936:	9f99                	subw	a5,a5,a4
    80000938:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000093a:	8526                	mv	a0,s1
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	b14080e7          	jalr	-1260(ra) # 80002450 <wakeup>
    
    WriteReg(THR, c);
    80000944:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000948:	409c                	lw	a5,0(s1)
    8000094a:	0009a703          	lw	a4,0(s3)
    8000094e:	fcf712e3          	bne	a4,a5,80000912 <uartstart+0x42>
  }
}
    80000952:	70e2                	ld	ra,56(sp)
    80000954:	7442                	ld	s0,48(sp)
    80000956:	74a2                	ld	s1,40(sp)
    80000958:	7902                	ld	s2,32(sp)
    8000095a:	69e2                	ld	s3,24(sp)
    8000095c:	6a42                	ld	s4,16(sp)
    8000095e:	6aa2                	ld	s5,8(sp)
    80000960:	6121                	addi	sp,sp,64
    80000962:	8082                	ret
    80000964:	8082                	ret

0000000080000966 <uartputc>:
{
    80000966:	7179                	addi	sp,sp,-48
    80000968:	f406                	sd	ra,40(sp)
    8000096a:	f022                	sd	s0,32(sp)
    8000096c:	ec26                	sd	s1,24(sp)
    8000096e:	e84a                	sd	s2,16(sp)
    80000970:	e44e                	sd	s3,8(sp)
    80000972:	e052                	sd	s4,0(sp)
    80000974:	1800                	addi	s0,sp,48
    80000976:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000978:	00011517          	auipc	a0,0x11
    8000097c:	f8050513          	addi	a0,a0,-128 # 800118f8 <uart_tx_lock>
    80000980:	00000097          	auipc	ra,0x0
    80000984:	316080e7          	jalr	790(ra) # 80000c96 <acquire>
  if(panicked){
    80000988:	00008797          	auipc	a5,0x8
    8000098c:	6787a783          	lw	a5,1656(a5) # 80009000 <panicked>
    80000990:	c391                	beqz	a5,80000994 <uartputc+0x2e>
    for(;;)
    80000992:	a001                	j	80000992 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000994:	00008717          	auipc	a4,0x8
    80000998:	67472703          	lw	a4,1652(a4) # 80009008 <uart_tx_w>
    8000099c:	0017079b          	addiw	a5,a4,1
    800009a0:	41f7d69b          	sraiw	a3,a5,0x1f
    800009a4:	01b6d69b          	srliw	a3,a3,0x1b
    800009a8:	9fb5                	addw	a5,a5,a3
    800009aa:	8bfd                	andi	a5,a5,31
    800009ac:	9f95                	subw	a5,a5,a3
    800009ae:	00008697          	auipc	a3,0x8
    800009b2:	6566a683          	lw	a3,1622(a3) # 80009004 <uart_tx_r>
    800009b6:	04f69263          	bne	a3,a5,800009fa <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009ba:	00011a17          	auipc	s4,0x11
    800009be:	f3ea0a13          	addi	s4,s4,-194 # 800118f8 <uart_tx_lock>
    800009c2:	00008497          	auipc	s1,0x8
    800009c6:	64248493          	addi	s1,s1,1602 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009ca:	00008917          	auipc	s2,0x8
    800009ce:	63e90913          	addi	s2,s2,1598 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009d2:	85d2                	mv	a1,s4
    800009d4:	8526                	mv	a0,s1
    800009d6:	00002097          	auipc	ra,0x2
    800009da:	8f4080e7          	jalr	-1804(ra) # 800022ca <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009de:	00092703          	lw	a4,0(s2)
    800009e2:	0017079b          	addiw	a5,a4,1
    800009e6:	41f7d69b          	sraiw	a3,a5,0x1f
    800009ea:	01b6d69b          	srliw	a3,a3,0x1b
    800009ee:	9fb5                	addw	a5,a5,a3
    800009f0:	8bfd                	andi	a5,a5,31
    800009f2:	9f95                	subw	a5,a5,a3
    800009f4:	4094                	lw	a3,0(s1)
    800009f6:	fcf68ee3          	beq	a3,a5,800009d2 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009fa:	00011497          	auipc	s1,0x11
    800009fe:	efe48493          	addi	s1,s1,-258 # 800118f8 <uart_tx_lock>
    80000a02:	9726                	add	a4,a4,s1
    80000a04:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000a08:	00008717          	auipc	a4,0x8
    80000a0c:	60f72023          	sw	a5,1536(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	ec0080e7          	jalr	-320(ra) # 800008d0 <uartstart>
      release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	330080e7          	jalr	816(ra) # 80000d4a <release>
}
    80000a22:	70a2                	ld	ra,40(sp)
    80000a24:	7402                	ld	s0,32(sp)
    80000a26:	64e2                	ld	s1,24(sp)
    80000a28:	6942                	ld	s2,16(sp)
    80000a2a:	69a2                	ld	s3,8(sp)
    80000a2c:	6a02                	ld	s4,0(sp)
    80000a2e:	6145                	addi	sp,sp,48
    80000a30:	8082                	ret

0000000080000a32 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a32:	1141                	addi	sp,sp,-16
    80000a34:	e422                	sd	s0,8(sp)
    80000a36:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a38:	100007b7          	lui	a5,0x10000
    80000a3c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a40:	8b85                	andi	a5,a5,1
    80000a42:	cb91                	beqz	a5,80000a56 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a44:	100007b7          	lui	a5,0x10000
    80000a48:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a4c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a50:	6422                	ld	s0,8(sp)
    80000a52:	0141                	addi	sp,sp,16
    80000a54:	8082                	ret
    return -1;
    80000a56:	557d                	li	a0,-1
    80000a58:	bfe5                	j	80000a50 <uartgetc+0x1e>

0000000080000a5a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a64:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	fcc080e7          	jalr	-52(ra) # 80000a32 <uartgetc>
    if(c == -1)
    80000a6e:	00950763          	beq	a0,s1,80000a7c <uartintr+0x22>
      break;
    consoleintr(c);
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	856080e7          	jalr	-1962(ra) # 800002c8 <consoleintr>
  while(1){
    80000a7a:	b7f5                	j	80000a66 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a7c:	00011497          	auipc	s1,0x11
    80000a80:	e7c48493          	addi	s1,s1,-388 # 800118f8 <uart_tx_lock>
    80000a84:	8526                	mv	a0,s1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	210080e7          	jalr	528(ra) # 80000c96 <acquire>
  uartstart();
    80000a8e:	00000097          	auipc	ra,0x0
    80000a92:	e42080e7          	jalr	-446(ra) # 800008d0 <uartstart>
  release(&uart_tx_lock);
    80000a96:	8526                	mv	a0,s1
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	2b2080e7          	jalr	690(ra) # 80000d4a <release>
}
    80000aa0:	60e2                	ld	ra,24(sp)
    80000aa2:	6442                	ld	s0,16(sp)
    80000aa4:	64a2                	ld	s1,8(sp)
    80000aa6:	6105                	addi	sp,sp,32
    80000aa8:	8082                	ret

0000000080000aaa <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000aaa:	1101                	addi	sp,sp,-32
    80000aac:	ec06                	sd	ra,24(sp)
    80000aae:	e822                	sd	s0,16(sp)
    80000ab0:	e426                	sd	s1,8(sp)
    80000ab2:	e04a                	sd	s2,0(sp)
    80000ab4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000ab6:	03451793          	slli	a5,a0,0x34
    80000aba:	ebb9                	bnez	a5,80000b10 <kfree+0x66>
    80000abc:	84aa                	mv	s1,a0
    80000abe:	00026797          	auipc	a5,0x26
    80000ac2:	54278793          	addi	a5,a5,1346 # 80027000 <end>
    80000ac6:	04f56563          	bltu	a0,a5,80000b10 <kfree+0x66>
    80000aca:	47c5                	li	a5,17
    80000acc:	07ee                	slli	a5,a5,0x1b
    80000ace:	04f57163          	bgeu	a0,a5,80000b10 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ad2:	6605                	lui	a2,0x1
    80000ad4:	4585                	li	a1,1
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	2bc080e7          	jalr	700(ra) # 80000d92 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ade:	00011917          	auipc	s2,0x11
    80000ae2:	e5290913          	addi	s2,s2,-430 # 80011930 <kmem>
    80000ae6:	854a                	mv	a0,s2
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	1ae080e7          	jalr	430(ra) # 80000c96 <acquire>
  r->next = kmem.freelist;
    80000af0:	01893783          	ld	a5,24(s2)
    80000af4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000af6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000afa:	854a                	mv	a0,s2
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	24e080e7          	jalr	590(ra) # 80000d4a <release>
}
    80000b04:	60e2                	ld	ra,24(sp)
    80000b06:	6442                	ld	s0,16(sp)
    80000b08:	64a2                	ld	s1,8(sp)
    80000b0a:	6902                	ld	s2,0(sp)
    80000b0c:	6105                	addi	sp,sp,32
    80000b0e:	8082                	ret
    panic("kfree");
    80000b10:	00007517          	auipc	a0,0x7
    80000b14:	56850513          	addi	a0,a0,1384 # 80008078 <digits+0x20>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	ae0080e7          	jalr	-1312(ra) # 800005f8 <panic>

0000000080000b20 <freerange>:
{
    80000b20:	7179                	addi	sp,sp,-48
    80000b22:	f406                	sd	ra,40(sp)
    80000b24:	f022                	sd	s0,32(sp)
    80000b26:	ec26                	sd	s1,24(sp)
    80000b28:	e84a                	sd	s2,16(sp)
    80000b2a:	e44e                	sd	s3,8(sp)
    80000b2c:	e052                	sd	s4,0(sp)
    80000b2e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b30:	6785                	lui	a5,0x1
    80000b32:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b36:	94aa                	add	s1,s1,a0
    80000b38:	757d                	lui	a0,0xfffff
    80000b3a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b3c:	94be                	add	s1,s1,a5
    80000b3e:	0095ee63          	bltu	a1,s1,80000b5a <freerange+0x3a>
    80000b42:	892e                	mv	s2,a1
    kfree(p);
    80000b44:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b46:	6985                	lui	s3,0x1
    kfree(p);
    80000b48:	01448533          	add	a0,s1,s4
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	f5e080e7          	jalr	-162(ra) # 80000aaa <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b54:	94ce                	add	s1,s1,s3
    80000b56:	fe9979e3          	bgeu	s2,s1,80000b48 <freerange+0x28>
}
    80000b5a:	70a2                	ld	ra,40(sp)
    80000b5c:	7402                	ld	s0,32(sp)
    80000b5e:	64e2                	ld	s1,24(sp)
    80000b60:	6942                	ld	s2,16(sp)
    80000b62:	69a2                	ld	s3,8(sp)
    80000b64:	6a02                	ld	s4,0(sp)
    80000b66:	6145                	addi	sp,sp,48
    80000b68:	8082                	ret

0000000080000b6a <kinit>:
{
    80000b6a:	1141                	addi	sp,sp,-16
    80000b6c:	e406                	sd	ra,8(sp)
    80000b6e:	e022                	sd	s0,0(sp)
    80000b70:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b72:	00007597          	auipc	a1,0x7
    80000b76:	50e58593          	addi	a1,a1,1294 # 80008080 <digits+0x28>
    80000b7a:	00011517          	auipc	a0,0x11
    80000b7e:	db650513          	addi	a0,a0,-586 # 80011930 <kmem>
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	084080e7          	jalr	132(ra) # 80000c06 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b8a:	45c5                	li	a1,17
    80000b8c:	05ee                	slli	a1,a1,0x1b
    80000b8e:	00026517          	auipc	a0,0x26
    80000b92:	47250513          	addi	a0,a0,1138 # 80027000 <end>
    80000b96:	00000097          	auipc	ra,0x0
    80000b9a:	f8a080e7          	jalr	-118(ra) # 80000b20 <freerange>
}
    80000b9e:	60a2                	ld	ra,8(sp)
    80000ba0:	6402                	ld	s0,0(sp)
    80000ba2:	0141                	addi	sp,sp,16
    80000ba4:	8082                	ret

0000000080000ba6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ba6:	1101                	addi	sp,sp,-32
    80000ba8:	ec06                	sd	ra,24(sp)
    80000baa:	e822                	sd	s0,16(sp)
    80000bac:	e426                	sd	s1,8(sp)
    80000bae:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bb0:	00011497          	auipc	s1,0x11
    80000bb4:	d8048493          	addi	s1,s1,-640 # 80011930 <kmem>
    80000bb8:	8526                	mv	a0,s1
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	0dc080e7          	jalr	220(ra) # 80000c96 <acquire>
  r = kmem.freelist;
    80000bc2:	6c84                	ld	s1,24(s1)
  if(r)
    80000bc4:	c885                	beqz	s1,80000bf4 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000bc6:	609c                	ld	a5,0(s1)
    80000bc8:	00011517          	auipc	a0,0x11
    80000bcc:	d6850513          	addi	a0,a0,-664 # 80011930 <kmem>
    80000bd0:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	178080e7          	jalr	376(ra) # 80000d4a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bda:	6605                	lui	a2,0x1
    80000bdc:	4595                	li	a1,5
    80000bde:	8526                	mv	a0,s1
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	1b2080e7          	jalr	434(ra) # 80000d92 <memset>
  return (void*)r;
}
    80000be8:	8526                	mv	a0,s1
    80000bea:	60e2                	ld	ra,24(sp)
    80000bec:	6442                	ld	s0,16(sp)
    80000bee:	64a2                	ld	s1,8(sp)
    80000bf0:	6105                	addi	sp,sp,32
    80000bf2:	8082                	ret
  release(&kmem.lock);
    80000bf4:	00011517          	auipc	a0,0x11
    80000bf8:	d3c50513          	addi	a0,a0,-708 # 80011930 <kmem>
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	14e080e7          	jalr	334(ra) # 80000d4a <release>
  if(r)
    80000c04:	b7d5                	j	80000be8 <kalloc+0x42>

0000000080000c06 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c06:	1141                	addi	sp,sp,-16
    80000c08:	e422                	sd	s0,8(sp)
    80000c0a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c0c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c0e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c12:	00053823          	sd	zero,16(a0)
}
    80000c16:	6422                	ld	s0,8(sp)
    80000c18:	0141                	addi	sp,sp,16
    80000c1a:	8082                	ret

0000000080000c1c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c1c:	411c                	lw	a5,0(a0)
    80000c1e:	e399                	bnez	a5,80000c24 <holding+0x8>
    80000c20:	4501                	li	a0,0
  return r;
}
    80000c22:	8082                	ret
{
    80000c24:	1101                	addi	sp,sp,-32
    80000c26:	ec06                	sd	ra,24(sp)
    80000c28:	e822                	sd	s0,16(sp)
    80000c2a:	e426                	sd	s1,8(sp)
    80000c2c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c2e:	6904                	ld	s1,16(a0)
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	e18080e7          	jalr	-488(ra) # 80001a48 <mycpu>
    80000c38:	40a48533          	sub	a0,s1,a0
    80000c3c:	00153513          	seqz	a0,a0
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret

0000000080000c4a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c4a:	1101                	addi	sp,sp,-32
    80000c4c:	ec06                	sd	ra,24(sp)
    80000c4e:	e822                	sd	s0,16(sp)
    80000c50:	e426                	sd	s1,8(sp)
    80000c52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c54:	100024f3          	csrr	s1,sstatus
    80000c58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	de6080e7          	jalr	-538(ra) # 80001a48 <mycpu>
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	cf89                	beqz	a5,80000c86 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c6e:	00001097          	auipc	ra,0x1
    80000c72:	dda080e7          	jalr	-550(ra) # 80001a48 <mycpu>
    80000c76:	5d3c                	lw	a5,120(a0)
    80000c78:	2785                	addiw	a5,a5,1
    80000c7a:	dd3c                	sw	a5,120(a0)
}
    80000c7c:	60e2                	ld	ra,24(sp)
    80000c7e:	6442                	ld	s0,16(sp)
    80000c80:	64a2                	ld	s1,8(sp)
    80000c82:	6105                	addi	sp,sp,32
    80000c84:	8082                	ret
    mycpu()->intena = old;
    80000c86:	00001097          	auipc	ra,0x1
    80000c8a:	dc2080e7          	jalr	-574(ra) # 80001a48 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c8e:	8085                	srli	s1,s1,0x1
    80000c90:	8885                	andi	s1,s1,1
    80000c92:	dd64                	sw	s1,124(a0)
    80000c94:	bfe9                	j	80000c6e <push_off+0x24>

0000000080000c96 <acquire>:
{
    80000c96:	1101                	addi	sp,sp,-32
    80000c98:	ec06                	sd	ra,24(sp)
    80000c9a:	e822                	sd	s0,16(sp)
    80000c9c:	e426                	sd	s1,8(sp)
    80000c9e:	1000                	addi	s0,sp,32
    80000ca0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	fa8080e7          	jalr	-88(ra) # 80000c4a <push_off>
  if(holding(lk))
    80000caa:	8526                	mv	a0,s1
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f70080e7          	jalr	-144(ra) # 80000c1c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb4:	4705                	li	a4,1
  if(holding(lk))
    80000cb6:	e115                	bnez	a0,80000cda <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cb8:	87ba                	mv	a5,a4
    80000cba:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cbe:	2781                	sext.w	a5,a5
    80000cc0:	ffe5                	bnez	a5,80000cb8 <acquire+0x22>
  __sync_synchronize();
    80000cc2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cc6:	00001097          	auipc	ra,0x1
    80000cca:	d82080e7          	jalr	-638(ra) # 80001a48 <mycpu>
    80000cce:	e888                	sd	a0,16(s1)
}
    80000cd0:	60e2                	ld	ra,24(sp)
    80000cd2:	6442                	ld	s0,16(sp)
    80000cd4:	64a2                	ld	s1,8(sp)
    80000cd6:	6105                	addi	sp,sp,32
    80000cd8:	8082                	ret
    panic("acquire");
    80000cda:	00007517          	auipc	a0,0x7
    80000cde:	3ae50513          	addi	a0,a0,942 # 80008088 <digits+0x30>
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	916080e7          	jalr	-1770(ra) # 800005f8 <panic>

0000000080000cea <pop_off>:

void
pop_off(void)
{
    80000cea:	1141                	addi	sp,sp,-16
    80000cec:	e406                	sd	ra,8(sp)
    80000cee:	e022                	sd	s0,0(sp)
    80000cf0:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cf2:	00001097          	auipc	ra,0x1
    80000cf6:	d56080e7          	jalr	-682(ra) # 80001a48 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cfa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cfe:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d00:	e78d                	bnez	a5,80000d2a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d02:	5d3c                	lw	a5,120(a0)
    80000d04:	02f05b63          	blez	a5,80000d3a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d08:	37fd                	addiw	a5,a5,-1
    80000d0a:	0007871b          	sext.w	a4,a5
    80000d0e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d10:	eb09                	bnez	a4,80000d22 <pop_off+0x38>
    80000d12:	5d7c                	lw	a5,124(a0)
    80000d14:	c799                	beqz	a5,80000d22 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d1e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d22:	60a2                	ld	ra,8(sp)
    80000d24:	6402                	ld	s0,0(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
    panic("pop_off - interruptible");
    80000d2a:	00007517          	auipc	a0,0x7
    80000d2e:	36650513          	addi	a0,a0,870 # 80008090 <digits+0x38>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	8c6080e7          	jalr	-1850(ra) # 800005f8 <panic>
    panic("pop_off");
    80000d3a:	00007517          	auipc	a0,0x7
    80000d3e:	36e50513          	addi	a0,a0,878 # 800080a8 <digits+0x50>
    80000d42:	00000097          	auipc	ra,0x0
    80000d46:	8b6080e7          	jalr	-1866(ra) # 800005f8 <panic>

0000000080000d4a <release>:
{
    80000d4a:	1101                	addi	sp,sp,-32
    80000d4c:	ec06                	sd	ra,24(sp)
    80000d4e:	e822                	sd	s0,16(sp)
    80000d50:	e426                	sd	s1,8(sp)
    80000d52:	1000                	addi	s0,sp,32
    80000d54:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	ec6080e7          	jalr	-314(ra) # 80000c1c <holding>
    80000d5e:	c115                	beqz	a0,80000d82 <release+0x38>
  lk->cpu = 0;
    80000d60:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d64:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d68:	0f50000f          	fence	iorw,ow
    80000d6c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	f7a080e7          	jalr	-134(ra) # 80000cea <pop_off>
}
    80000d78:	60e2                	ld	ra,24(sp)
    80000d7a:	6442                	ld	s0,16(sp)
    80000d7c:	64a2                	ld	s1,8(sp)
    80000d7e:	6105                	addi	sp,sp,32
    80000d80:	8082                	ret
    panic("release");
    80000d82:	00007517          	auipc	a0,0x7
    80000d86:	32e50513          	addi	a0,a0,814 # 800080b0 <digits+0x58>
    80000d8a:	00000097          	auipc	ra,0x0
    80000d8e:	86e080e7          	jalr	-1938(ra) # 800005f8 <panic>

0000000080000d92 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d92:	1141                	addi	sp,sp,-16
    80000d94:	e422                	sd	s0,8(sp)
    80000d96:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d98:	ce09                	beqz	a2,80000db2 <memset+0x20>
    80000d9a:	87aa                	mv	a5,a0
    80000d9c:	fff6071b          	addiw	a4,a2,-1
    80000da0:	1702                	slli	a4,a4,0x20
    80000da2:	9301                	srli	a4,a4,0x20
    80000da4:	0705                	addi	a4,a4,1
    80000da6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000da8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dac:	0785                	addi	a5,a5,1
    80000dae:	fee79de3          	bne	a5,a4,80000da8 <memset+0x16>
  }
  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dbe:	ca05                	beqz	a2,80000dee <memcmp+0x36>
    80000dc0:	fff6069b          	addiw	a3,a2,-1
    80000dc4:	1682                	slli	a3,a3,0x20
    80000dc6:	9281                	srli	a3,a3,0x20
    80000dc8:	0685                	addi	a3,a3,1
    80000dca:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dcc:	00054783          	lbu	a5,0(a0)
    80000dd0:	0005c703          	lbu	a4,0(a1)
    80000dd4:	00e79863          	bne	a5,a4,80000de4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dd8:	0505                	addi	a0,a0,1
    80000dda:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ddc:	fed518e3          	bne	a0,a3,80000dcc <memcmp+0x14>
  }

  return 0;
    80000de0:	4501                	li	a0,0
    80000de2:	a019                	j	80000de8 <memcmp+0x30>
      return *s1 - *s2;
    80000de4:	40e7853b          	subw	a0,a5,a4
}
    80000de8:	6422                	ld	s0,8(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret
  return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	bfe5                	j	80000de8 <memcmp+0x30>

0000000080000df2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df2:	1141                	addi	sp,sp,-16
    80000df4:	e422                	sd	s0,8(sp)
    80000df6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000df8:	00a5f963          	bgeu	a1,a0,80000e0a <memmove+0x18>
    80000dfc:	02061713          	slli	a4,a2,0x20
    80000e00:	9301                	srli	a4,a4,0x20
    80000e02:	00e587b3          	add	a5,a1,a4
    80000e06:	02f56563          	bltu	a0,a5,80000e30 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	ce11                	beqz	a2,80000e2a <memmove+0x38>
    80000e10:	1682                	slli	a3,a3,0x20
    80000e12:	9281                	srli	a3,a3,0x20
    80000e14:	0685                	addi	a3,a3,1
    80000e16:	96ae                	add	a3,a3,a1
    80000e18:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e1a:	0585                	addi	a1,a1,1
    80000e1c:	0785                	addi	a5,a5,1
    80000e1e:	fff5c703          	lbu	a4,-1(a1)
    80000e22:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e26:	fed59ae3          	bne	a1,a3,80000e1a <memmove+0x28>

  return dst;
}
    80000e2a:	6422                	ld	s0,8(sp)
    80000e2c:	0141                	addi	sp,sp,16
    80000e2e:	8082                	ret
    d += n;
    80000e30:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	da75                	beqz	a2,80000e2a <memmove+0x38>
    80000e38:	02069613          	slli	a2,a3,0x20
    80000e3c:	9201                	srli	a2,a2,0x20
    80000e3e:	fff64613          	not	a2,a2
    80000e42:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e44:	17fd                	addi	a5,a5,-1
    80000e46:	177d                	addi	a4,a4,-1
    80000e48:	0007c683          	lbu	a3,0(a5)
    80000e4c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e50:	fec79ae3          	bne	a5,a2,80000e44 <memmove+0x52>
    80000e54:	bfd9                	j	80000e2a <memmove+0x38>

0000000080000e56 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e406                	sd	ra,8(sp)
    80000e5a:	e022                	sd	s0,0(sp)
    80000e5c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e5e:	00000097          	auipc	ra,0x0
    80000e62:	f94080e7          	jalr	-108(ra) # 80000df2 <memmove>
}
    80000e66:	60a2                	ld	ra,8(sp)
    80000e68:	6402                	ld	s0,0(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret

0000000080000e6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e74:	ce11                	beqz	a2,80000e90 <strncmp+0x22>
    80000e76:	00054783          	lbu	a5,0(a0)
    80000e7a:	cf89                	beqz	a5,80000e94 <strncmp+0x26>
    80000e7c:	0005c703          	lbu	a4,0(a1)
    80000e80:	00f71a63          	bne	a4,a5,80000e94 <strncmp+0x26>
    n--, p++, q++;
    80000e84:	367d                	addiw	a2,a2,-1
    80000e86:	0505                	addi	a0,a0,1
    80000e88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e8a:	f675                	bnez	a2,80000e76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e8c:	4501                	li	a0,0
    80000e8e:	a809                	j	80000ea0 <strncmp+0x32>
    80000e90:	4501                	li	a0,0
    80000e92:	a039                	j	80000ea0 <strncmp+0x32>
  if(n == 0)
    80000e94:	ca09                	beqz	a2,80000ea6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e96:	00054503          	lbu	a0,0(a0)
    80000e9a:	0005c783          	lbu	a5,0(a1)
    80000e9e:	9d1d                	subw	a0,a0,a5
}
    80000ea0:	6422                	ld	s0,8(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret
    return 0;
    80000ea6:	4501                	li	a0,0
    80000ea8:	bfe5                	j	80000ea0 <strncmp+0x32>

0000000080000eaa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e422                	sd	s0,8(sp)
    80000eae:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eb0:	872a                	mv	a4,a0
    80000eb2:	8832                	mv	a6,a2
    80000eb4:	367d                	addiw	a2,a2,-1
    80000eb6:	01005963          	blez	a6,80000ec8 <strncpy+0x1e>
    80000eba:	0705                	addi	a4,a4,1
    80000ebc:	0005c783          	lbu	a5,0(a1)
    80000ec0:	fef70fa3          	sb	a5,-1(a4)
    80000ec4:	0585                	addi	a1,a1,1
    80000ec6:	f7f5                	bnez	a5,80000eb2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec8:	00c05d63          	blez	a2,80000ee2 <strncpy+0x38>
    80000ecc:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ece:	0685                	addi	a3,a3,1
    80000ed0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ed4:	fff6c793          	not	a5,a3
    80000ed8:	9fb9                	addw	a5,a5,a4
    80000eda:	010787bb          	addw	a5,a5,a6
    80000ede:	fef048e3          	bgtz	a5,80000ece <strncpy+0x24>
  return os;
}
    80000ee2:	6422                	ld	s0,8(sp)
    80000ee4:	0141                	addi	sp,sp,16
    80000ee6:	8082                	ret

0000000080000ee8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e422                	sd	s0,8(sp)
    80000eec:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eee:	02c05363          	blez	a2,80000f14 <safestrcpy+0x2c>
    80000ef2:	fff6069b          	addiw	a3,a2,-1
    80000ef6:	1682                	slli	a3,a3,0x20
    80000ef8:	9281                	srli	a3,a3,0x20
    80000efa:	96ae                	add	a3,a3,a1
    80000efc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000efe:	00d58963          	beq	a1,a3,80000f10 <safestrcpy+0x28>
    80000f02:	0585                	addi	a1,a1,1
    80000f04:	0785                	addi	a5,a5,1
    80000f06:	fff5c703          	lbu	a4,-1(a1)
    80000f0a:	fee78fa3          	sb	a4,-1(a5)
    80000f0e:	fb65                	bnez	a4,80000efe <safestrcpy+0x16>
    ;
  *s = 0;
    80000f10:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f14:	6422                	ld	s0,8(sp)
    80000f16:	0141                	addi	sp,sp,16
    80000f18:	8082                	ret

0000000080000f1a <strlen>:

int
strlen(const char *s)
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e422                	sd	s0,8(sp)
    80000f1e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f20:	00054783          	lbu	a5,0(a0)
    80000f24:	cf91                	beqz	a5,80000f40 <strlen+0x26>
    80000f26:	0505                	addi	a0,a0,1
    80000f28:	87aa                	mv	a5,a0
    80000f2a:	4685                	li	a3,1
    80000f2c:	9e89                	subw	a3,a3,a0
    80000f2e:	00f6853b          	addw	a0,a3,a5
    80000f32:	0785                	addi	a5,a5,1
    80000f34:	fff7c703          	lbu	a4,-1(a5)
    80000f38:	fb7d                	bnez	a4,80000f2e <strlen+0x14>
    ;
  return n;
}
    80000f3a:	6422                	ld	s0,8(sp)
    80000f3c:	0141                	addi	sp,sp,16
    80000f3e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f40:	4501                	li	a0,0
    80000f42:	bfe5                	j	80000f3a <strlen+0x20>

0000000080000f44 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f44:	1141                	addi	sp,sp,-16
    80000f46:	e406                	sd	ra,8(sp)
    80000f48:	e022                	sd	s0,0(sp)
    80000f4a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aec080e7          	jalr	-1300(ra) # 80001a38 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f54:	00008717          	auipc	a4,0x8
    80000f58:	0b870713          	addi	a4,a4,184 # 8000900c <started>
  if(cpuid() == 0){
    80000f5c:	c139                	beqz	a0,80000fa2 <main+0x5e>
    while(started == 0)
    80000f5e:	431c                	lw	a5,0(a4)
    80000f60:	2781                	sext.w	a5,a5
    80000f62:	dff5                	beqz	a5,80000f5e <main+0x1a>
      ;
    __sync_synchronize();
    80000f64:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	ad0080e7          	jalr	-1328(ra) # 80001a38 <cpuid>
    80000f70:	85aa                	mv	a1,a0
    80000f72:	00007517          	auipc	a0,0x7
    80000f76:	15e50513          	addi	a0,a0,350 # 800080d0 <digits+0x78>
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	6d0080e7          	jalr	1744(ra) # 8000064a <printf>
    kvminithart();    // turn on paging
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	0d8080e7          	jalr	216(ra) # 8000105a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	78e080e7          	jalr	1934(ra) # 80002718 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	dfe080e7          	jalr	-514(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000f9a:	00001097          	auipc	ra,0x1
    80000f9e:	054080e7          	jalr	84(ra) # 80001fee <scheduler>
    consoleinit();
    80000fa2:	fffff097          	auipc	ra,0xfffff
    80000fa6:	4b8080e7          	jalr	1208(ra) # 8000045a <consoleinit>
    printfinit();
    80000faa:	fffff097          	auipc	ra,0xfffff
    80000fae:	59e080e7          	jalr	1438(ra) # 80000548 <printfinit>
    printf("\n");
    80000fb2:	00007517          	auipc	a0,0x7
    80000fb6:	12e50513          	addi	a0,a0,302 # 800080e0 <digits+0x88>
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	690080e7          	jalr	1680(ra) # 8000064a <printf>
    printf("xv6 kernel is booting\n");
    80000fc2:	00007517          	auipc	a0,0x7
    80000fc6:	0f650513          	addi	a0,a0,246 # 800080b8 <digits+0x60>
    80000fca:	fffff097          	auipc	ra,0xfffff
    80000fce:	680080e7          	jalr	1664(ra) # 8000064a <printf>
    printf("\n");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	10e50513          	addi	a0,a0,270 # 800080e0 <digits+0x88>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	670080e7          	jalr	1648(ra) # 8000064a <printf>
    kinit();         // physical page allocator
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	b88080e7          	jalr	-1144(ra) # 80000b6a <kinit>
    kvminit();       // create kernel page table
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	2a0080e7          	jalr	672(ra) # 8000128a <kvminit>
    kvminithart();   // turn on paging
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	068080e7          	jalr	104(ra) # 8000105a <kvminithart>
    procinit();      // process table
    80000ffa:	00001097          	auipc	ra,0x1
    80000ffe:	96e080e7          	jalr	-1682(ra) # 80001968 <procinit>
    trapinit();      // trap vectors
    80001002:	00001097          	auipc	ra,0x1
    80001006:	6ee080e7          	jalr	1774(ra) # 800026f0 <trapinit>
    trapinithart();  // install kernel trap vector
    8000100a:	00001097          	auipc	ra,0x1
    8000100e:	70e080e7          	jalr	1806(ra) # 80002718 <trapinithart>
    plicinit();      // set up interrupt controller
    80001012:	00005097          	auipc	ra,0x5
    80001016:	d68080e7          	jalr	-664(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000101a:	00005097          	auipc	ra,0x5
    8000101e:	d76080e7          	jalr	-650(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80001022:	00002097          	auipc	ra,0x2
    80001026:	f1c080e7          	jalr	-228(ra) # 80002f3e <binit>
    iinit();         // inode cache
    8000102a:	00002097          	auipc	ra,0x2
    8000102e:	5ac080e7          	jalr	1452(ra) # 800035d6 <iinit>
    fileinit();      // file table
    80001032:	00003097          	auipc	ra,0x3
    80001036:	546080e7          	jalr	1350(ra) # 80004578 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000103a:	00005097          	auipc	ra,0x5
    8000103e:	e5e080e7          	jalr	-418(ra) # 80005e98 <virtio_disk_init>
    userinit();      // first user process
    80001042:	00001097          	auipc	ra,0x1
    80001046:	d46080e7          	jalr	-698(ra) # 80001d88 <userinit>
    __sync_synchronize();
    8000104a:	0ff0000f          	fence
    started = 1;
    8000104e:	4785                	li	a5,1
    80001050:	00008717          	auipc	a4,0x8
    80001054:	faf72e23          	sw	a5,-68(a4) # 8000900c <started>
    80001058:	b789                	j	80000f9a <main+0x56>

000000008000105a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000105a:	1141                	addi	sp,sp,-16
    8000105c:	e422                	sd	s0,8(sp)
    8000105e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001060:	00008797          	auipc	a5,0x8
    80001064:	fb07b783          	ld	a5,-80(a5) # 80009010 <kernel_pagetable>
    80001068:	83b1                	srli	a5,a5,0xc
    8000106a:	577d                	li	a4,-1
    8000106c:	177e                	slli	a4,a4,0x3f
    8000106e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001070:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001074:	12000073          	sfence.vma
  sfence_vma();
}
    80001078:	6422                	ld	s0,8(sp)
    8000107a:	0141                	addi	sp,sp,16
    8000107c:	8082                	ret

000000008000107e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107e:	7139                	addi	sp,sp,-64
    80001080:	fc06                	sd	ra,56(sp)
    80001082:	f822                	sd	s0,48(sp)
    80001084:	f426                	sd	s1,40(sp)
    80001086:	f04a                	sd	s2,32(sp)
    80001088:	ec4e                	sd	s3,24(sp)
    8000108a:	e852                	sd	s4,16(sp)
    8000108c:	e456                	sd	s5,8(sp)
    8000108e:	e05a                	sd	s6,0(sp)
    80001090:	0080                	addi	s0,sp,64
    80001092:	84aa                	mv	s1,a0
    80001094:	89ae                	mv	s3,a1
    80001096:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001098:	57fd                	li	a5,-1
    8000109a:	83e9                	srli	a5,a5,0x1a
    8000109c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109e:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010a0:	04b7f263          	bgeu	a5,a1,800010e4 <walk+0x66>
    panic("walk");
    800010a4:	00007517          	auipc	a0,0x7
    800010a8:	04450513          	addi	a0,a0,68 # 800080e8 <digits+0x90>
    800010ac:	fffff097          	auipc	ra,0xfffff
    800010b0:	54c080e7          	jalr	1356(ra) # 800005f8 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010b4:	060a8663          	beqz	s5,80001120 <walk+0xa2>
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	aee080e7          	jalr	-1298(ra) # 80000ba6 <kalloc>
    800010c0:	84aa                	mv	s1,a0
    800010c2:	c529                	beqz	a0,8000110c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010c4:	6605                	lui	a2,0x1
    800010c6:	4581                	li	a1,0
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	cca080e7          	jalr	-822(ra) # 80000d92 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010d0:	00c4d793          	srli	a5,s1,0xc
    800010d4:	07aa                	slli	a5,a5,0xa
    800010d6:	0017e793          	ori	a5,a5,1
    800010da:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010de:	3a5d                	addiw	s4,s4,-9
    800010e0:	036a0063          	beq	s4,s6,80001100 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010e4:	0149d933          	srl	s2,s3,s4
    800010e8:	1ff97913          	andi	s2,s2,511
    800010ec:	090e                	slli	s2,s2,0x3
    800010ee:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010f0:	00093483          	ld	s1,0(s2)
    800010f4:	0014f793          	andi	a5,s1,1
    800010f8:	dfd5                	beqz	a5,800010b4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010fa:	80a9                	srli	s1,s1,0xa
    800010fc:	04b2                	slli	s1,s1,0xc
    800010fe:	b7c5                	j	800010de <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001100:	00c9d513          	srli	a0,s3,0xc
    80001104:	1ff57513          	andi	a0,a0,511
    80001108:	050e                	slli	a0,a0,0x3
    8000110a:	9526                	add	a0,a0,s1
}
    8000110c:	70e2                	ld	ra,56(sp)
    8000110e:	7442                	ld	s0,48(sp)
    80001110:	74a2                	ld	s1,40(sp)
    80001112:	7902                	ld	s2,32(sp)
    80001114:	69e2                	ld	s3,24(sp)
    80001116:	6a42                	ld	s4,16(sp)
    80001118:	6aa2                	ld	s5,8(sp)
    8000111a:	6b02                	ld	s6,0(sp)
    8000111c:	6121                	addi	sp,sp,64
    8000111e:	8082                	ret
        return 0;
    80001120:	4501                	li	a0,0
    80001122:	b7ed                	j	8000110c <walk+0x8e>

0000000080001124 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001124:	57fd                	li	a5,-1
    80001126:	83e9                	srli	a5,a5,0x1a
    80001128:	00b7f463          	bgeu	a5,a1,80001130 <walkaddr+0xc>
    return 0;
    8000112c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112e:	8082                	ret
{
    80001130:	1141                	addi	sp,sp,-16
    80001132:	e406                	sd	ra,8(sp)
    80001134:	e022                	sd	s0,0(sp)
    80001136:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f44080e7          	jalr	-188(ra) # 8000107e <walk>
  if(pte == 0)
    80001142:	c105                	beqz	a0,80001162 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001144:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001146:	0117f693          	andi	a3,a5,17
    8000114a:	4745                	li	a4,17
    return 0;
    8000114c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114e:	00e68663          	beq	a3,a4,8000115a <walkaddr+0x36>
}
    80001152:	60a2                	ld	ra,8(sp)
    80001154:	6402                	ld	s0,0(sp)
    80001156:	0141                	addi	sp,sp,16
    80001158:	8082                	ret
  pa = PTE2PA(*pte);
    8000115a:	00a7d513          	srli	a0,a5,0xa
    8000115e:	0532                	slli	a0,a0,0xc
  return pa;
    80001160:	bfcd                	j	80001152 <walkaddr+0x2e>
    return 0;
    80001162:	4501                	li	a0,0
    80001164:	b7fd                	j	80001152 <walkaddr+0x2e>

0000000080001166 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001166:	1101                	addi	sp,sp,-32
    80001168:	ec06                	sd	ra,24(sp)
    8000116a:	e822                	sd	s0,16(sp)
    8000116c:	e426                	sd	s1,8(sp)
    8000116e:	1000                	addi	s0,sp,32
    80001170:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001172:	1552                	slli	a0,a0,0x34
    80001174:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001178:	4601                	li	a2,0
    8000117a:	00008517          	auipc	a0,0x8
    8000117e:	e9653503          	ld	a0,-362(a0) # 80009010 <kernel_pagetable>
    80001182:	00000097          	auipc	ra,0x0
    80001186:	efc080e7          	jalr	-260(ra) # 8000107e <walk>
  if(pte == 0)
    8000118a:	cd09                	beqz	a0,800011a4 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000118c:	6108                	ld	a0,0(a0)
    8000118e:	00157793          	andi	a5,a0,1
    80001192:	c38d                	beqz	a5,800011b4 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001194:	8129                	srli	a0,a0,0xa
    80001196:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001198:	9526                	add	a0,a0,s1
    8000119a:	60e2                	ld	ra,24(sp)
    8000119c:	6442                	ld	s0,16(sp)
    8000119e:	64a2                	ld	s1,8(sp)
    800011a0:	6105                	addi	sp,sp,32
    800011a2:	8082                	ret
    panic("kvmpa");
    800011a4:	00007517          	auipc	a0,0x7
    800011a8:	f4c50513          	addi	a0,a0,-180 # 800080f0 <digits+0x98>
    800011ac:	fffff097          	auipc	ra,0xfffff
    800011b0:	44c080e7          	jalr	1100(ra) # 800005f8 <panic>
    panic("kvmpa");
    800011b4:	00007517          	auipc	a0,0x7
    800011b8:	f3c50513          	addi	a0,a0,-196 # 800080f0 <digits+0x98>
    800011bc:	fffff097          	auipc	ra,0xfffff
    800011c0:	43c080e7          	jalr	1084(ra) # 800005f8 <panic>

00000000800011c4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011c4:	715d                	addi	sp,sp,-80
    800011c6:	e486                	sd	ra,72(sp)
    800011c8:	e0a2                	sd	s0,64(sp)
    800011ca:	fc26                	sd	s1,56(sp)
    800011cc:	f84a                	sd	s2,48(sp)
    800011ce:	f44e                	sd	s3,40(sp)
    800011d0:	f052                	sd	s4,32(sp)
    800011d2:	ec56                	sd	s5,24(sp)
    800011d4:	e85a                	sd	s6,16(sp)
    800011d6:	e45e                	sd	s7,8(sp)
    800011d8:	0880                	addi	s0,sp,80
    800011da:	8aaa                	mv	s5,a0
    800011dc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011de:	777d                	lui	a4,0xfffff
    800011e0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011e4:	167d                	addi	a2,a2,-1
    800011e6:	00b609b3          	add	s3,a2,a1
    800011ea:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ee:	893e                	mv	s2,a5
    800011f0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011f4:	6b85                	lui	s7,0x1
    800011f6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011fa:	4605                	li	a2,1
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8556                	mv	a0,s5
    80001200:	00000097          	auipc	ra,0x0
    80001204:	e7e080e7          	jalr	-386(ra) # 8000107e <walk>
    80001208:	c51d                	beqz	a0,80001236 <mappages+0x72>
    if(*pte & PTE_V)
    8000120a:	611c                	ld	a5,0(a0)
    8000120c:	8b85                	andi	a5,a5,1
    8000120e:	ef81                	bnez	a5,80001226 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001210:	80b1                	srli	s1,s1,0xc
    80001212:	04aa                	slli	s1,s1,0xa
    80001214:	0164e4b3          	or	s1,s1,s6
    80001218:	0014e493          	ori	s1,s1,1
    8000121c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000121e:	03390863          	beq	s2,s3,8000124e <mappages+0x8a>
    a += PGSIZE;
    80001222:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001224:	bfc9                	j	800011f6 <mappages+0x32>
      panic("remap");
    80001226:	00007517          	auipc	a0,0x7
    8000122a:	ed250513          	addi	a0,a0,-302 # 800080f8 <digits+0xa0>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	3ca080e7          	jalr	970(ra) # 800005f8 <panic>
      return -1;
    80001236:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001238:	60a6                	ld	ra,72(sp)
    8000123a:	6406                	ld	s0,64(sp)
    8000123c:	74e2                	ld	s1,56(sp)
    8000123e:	7942                	ld	s2,48(sp)
    80001240:	79a2                	ld	s3,40(sp)
    80001242:	7a02                	ld	s4,32(sp)
    80001244:	6ae2                	ld	s5,24(sp)
    80001246:	6b42                	ld	s6,16(sp)
    80001248:	6ba2                	ld	s7,8(sp)
    8000124a:	6161                	addi	sp,sp,80
    8000124c:	8082                	ret
  return 0;
    8000124e:	4501                	li	a0,0
    80001250:	b7e5                	j	80001238 <mappages+0x74>

0000000080001252 <kvmmap>:
{
    80001252:	1141                	addi	sp,sp,-16
    80001254:	e406                	sd	ra,8(sp)
    80001256:	e022                	sd	s0,0(sp)
    80001258:	0800                	addi	s0,sp,16
    8000125a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000125c:	86ae                	mv	a3,a1
    8000125e:	85aa                	mv	a1,a0
    80001260:	00008517          	auipc	a0,0x8
    80001264:	db053503          	ld	a0,-592(a0) # 80009010 <kernel_pagetable>
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f5c080e7          	jalr	-164(ra) # 800011c4 <mappages>
    80001270:	e509                	bnez	a0,8000127a <kvmmap+0x28>
}
    80001272:	60a2                	ld	ra,8(sp)
    80001274:	6402                	ld	s0,0(sp)
    80001276:	0141                	addi	sp,sp,16
    80001278:	8082                	ret
    panic("kvmmap");
    8000127a:	00007517          	auipc	a0,0x7
    8000127e:	e8650513          	addi	a0,a0,-378 # 80008100 <digits+0xa8>
    80001282:	fffff097          	auipc	ra,0xfffff
    80001286:	376080e7          	jalr	886(ra) # 800005f8 <panic>

000000008000128a <kvminit>:
{
    8000128a:	1101                	addi	sp,sp,-32
    8000128c:	ec06                	sd	ra,24(sp)
    8000128e:	e822                	sd	s0,16(sp)
    80001290:	e426                	sd	s1,8(sp)
    80001292:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001294:	00000097          	auipc	ra,0x0
    80001298:	912080e7          	jalr	-1774(ra) # 80000ba6 <kalloc>
    8000129c:	00008797          	auipc	a5,0x8
    800012a0:	d6a7ba23          	sd	a0,-652(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012a4:	6605                	lui	a2,0x1
    800012a6:	4581                	li	a1,0
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	aea080e7          	jalr	-1302(ra) # 80000d92 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	6605                	lui	a2,0x1
    800012b4:	100005b7          	lui	a1,0x10000
    800012b8:	10000537          	lui	a0,0x10000
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	f96080e7          	jalr	-106(ra) # 80001252 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012c4:	4699                	li	a3,6
    800012c6:	6605                	lui	a2,0x1
    800012c8:	100015b7          	lui	a1,0x10001
    800012cc:	10001537          	lui	a0,0x10001
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f82080e7          	jalr	-126(ra) # 80001252 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012d8:	4699                	li	a3,6
    800012da:	6641                	lui	a2,0x10
    800012dc:	020005b7          	lui	a1,0x2000
    800012e0:	02000537          	lui	a0,0x2000
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f6e080e7          	jalr	-146(ra) # 80001252 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ec:	4699                	li	a3,6
    800012ee:	00400637          	lui	a2,0x400
    800012f2:	0c0005b7          	lui	a1,0xc000
    800012f6:	0c000537          	lui	a0,0xc000
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f58080e7          	jalr	-168(ra) # 80001252 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001302:	00007497          	auipc	s1,0x7
    80001306:	cfe48493          	addi	s1,s1,-770 # 80008000 <etext>
    8000130a:	46a9                	li	a3,10
    8000130c:	80007617          	auipc	a2,0x80007
    80001310:	cf460613          	addi	a2,a2,-780 # 8000 <_entry-0x7fff8000>
    80001314:	4585                	li	a1,1
    80001316:	05fe                	slli	a1,a1,0x1f
    80001318:	852e                	mv	a0,a1
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	f38080e7          	jalr	-200(ra) # 80001252 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001322:	4699                	li	a3,6
    80001324:	4645                	li	a2,17
    80001326:	066e                	slli	a2,a2,0x1b
    80001328:	8e05                	sub	a2,a2,s1
    8000132a:	85a6                	mv	a1,s1
    8000132c:	8526                	mv	a0,s1
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	f24080e7          	jalr	-220(ra) # 80001252 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001336:	46a9                	li	a3,10
    80001338:	6605                	lui	a2,0x1
    8000133a:	00006597          	auipc	a1,0x6
    8000133e:	cc658593          	addi	a1,a1,-826 # 80007000 <_trampoline>
    80001342:	04000537          	lui	a0,0x4000
    80001346:	157d                	addi	a0,a0,-1
    80001348:	0532                	slli	a0,a0,0xc
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f08080e7          	jalr	-248(ra) # 80001252 <kvmmap>
}
    80001352:	60e2                	ld	ra,24(sp)
    80001354:	6442                	ld	s0,16(sp)
    80001356:	64a2                	ld	s1,8(sp)
    80001358:	6105                	addi	sp,sp,32
    8000135a:	8082                	ret

000000008000135c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000135c:	715d                	addi	sp,sp,-80
    8000135e:	e486                	sd	ra,72(sp)
    80001360:	e0a2                	sd	s0,64(sp)
    80001362:	fc26                	sd	s1,56(sp)
    80001364:	f84a                	sd	s2,48(sp)
    80001366:	f44e                	sd	s3,40(sp)
    80001368:	f052                	sd	s4,32(sp)
    8000136a:	ec56                	sd	s5,24(sp)
    8000136c:	e85a                	sd	s6,16(sp)
    8000136e:	e45e                	sd	s7,8(sp)
    80001370:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001372:	03459793          	slli	a5,a1,0x34
    80001376:	e795                	bnez	a5,800013a2 <uvmunmap+0x46>
    80001378:	8a2a                	mv	s4,a0
    8000137a:	892e                	mv	s2,a1
    8000137c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137e:	0632                	slli	a2,a2,0xc
    80001380:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001384:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001386:	6b05                	lui	s6,0x1
    80001388:	0735e863          	bltu	a1,s3,800013f8 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000138c:	60a6                	ld	ra,72(sp)
    8000138e:	6406                	ld	s0,64(sp)
    80001390:	74e2                	ld	s1,56(sp)
    80001392:	7942                	ld	s2,48(sp)
    80001394:	79a2                	ld	s3,40(sp)
    80001396:	7a02                	ld	s4,32(sp)
    80001398:	6ae2                	ld	s5,24(sp)
    8000139a:	6b42                	ld	s6,16(sp)
    8000139c:	6ba2                	ld	s7,8(sp)
    8000139e:	6161                	addi	sp,sp,80
    800013a0:	8082                	ret
    panic("uvmunmap: not aligned");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	d6650513          	addi	a0,a0,-666 # 80008108 <digits+0xb0>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	24e080e7          	jalr	590(ra) # 800005f8 <panic>
      panic("uvmunmap: walk");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	d6e50513          	addi	a0,a0,-658 # 80008120 <digits+0xc8>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	23e080e7          	jalr	574(ra) # 800005f8 <panic>
      panic("uvmunmap: not mapped");
    800013c2:	00007517          	auipc	a0,0x7
    800013c6:	d6e50513          	addi	a0,a0,-658 # 80008130 <digits+0xd8>
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	22e080e7          	jalr	558(ra) # 800005f8 <panic>
      panic("uvmunmap: not a leaf");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d7650513          	addi	a0,a0,-650 # 80008148 <digits+0xf0>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	21e080e7          	jalr	542(ra) # 800005f8 <panic>
      uint64 pa = PTE2PA(*pte);
    800013e2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013e4:	0532                	slli	a0,a0,0xc
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	6c4080e7          	jalr	1732(ra) # 80000aaa <kfree>
    *pte = 0;
    800013ee:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f2:	995a                	add	s2,s2,s6
    800013f4:	f9397ce3          	bgeu	s2,s3,8000138c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013f8:	4601                	li	a2,0
    800013fa:	85ca                	mv	a1,s2
    800013fc:	8552                	mv	a0,s4
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	c80080e7          	jalr	-896(ra) # 8000107e <walk>
    80001406:	84aa                	mv	s1,a0
    80001408:	d54d                	beqz	a0,800013b2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000140a:	6108                	ld	a0,0(a0)
    8000140c:	00157793          	andi	a5,a0,1
    80001410:	dbcd                	beqz	a5,800013c2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001412:	3ff57793          	andi	a5,a0,1023
    80001416:	fb778ee3          	beq	a5,s7,800013d2 <uvmunmap+0x76>
    if(do_free){
    8000141a:	fc0a8ae3          	beqz	s5,800013ee <uvmunmap+0x92>
    8000141e:	b7d1                	j	800013e2 <uvmunmap+0x86>

0000000080001420 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001420:	1101                	addi	sp,sp,-32
    80001422:	ec06                	sd	ra,24(sp)
    80001424:	e822                	sd	s0,16(sp)
    80001426:	e426                	sd	s1,8(sp)
    80001428:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	77c080e7          	jalr	1916(ra) # 80000ba6 <kalloc>
    80001432:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001434:	c519                	beqz	a0,80001442 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001436:	6605                	lui	a2,0x1
    80001438:	4581                	li	a1,0
    8000143a:	00000097          	auipc	ra,0x0
    8000143e:	958080e7          	jalr	-1704(ra) # 80000d92 <memset>
  return pagetable;
}
    80001442:	8526                	mv	a0,s1
    80001444:	60e2                	ld	ra,24(sp)
    80001446:	6442                	ld	s0,16(sp)
    80001448:	64a2                	ld	s1,8(sp)
    8000144a:	6105                	addi	sp,sp,32
    8000144c:	8082                	ret

000000008000144e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000144e:	7179                	addi	sp,sp,-48
    80001450:	f406                	sd	ra,40(sp)
    80001452:	f022                	sd	s0,32(sp)
    80001454:	ec26                	sd	s1,24(sp)
    80001456:	e84a                	sd	s2,16(sp)
    80001458:	e44e                	sd	s3,8(sp)
    8000145a:	e052                	sd	s4,0(sp)
    8000145c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000145e:	6785                	lui	a5,0x1
    80001460:	04f67863          	bgeu	a2,a5,800014b0 <uvminit+0x62>
    80001464:	8a2a                	mv	s4,a0
    80001466:	89ae                	mv	s3,a1
    80001468:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	73c080e7          	jalr	1852(ra) # 80000ba6 <kalloc>
    80001472:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	91a080e7          	jalr	-1766(ra) # 80000d92 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001480:	4779                	li	a4,30
    80001482:	86ca                	mv	a3,s2
    80001484:	6605                	lui	a2,0x1
    80001486:	4581                	li	a1,0
    80001488:	8552                	mv	a0,s4
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	d3a080e7          	jalr	-710(ra) # 800011c4 <mappages>
  memmove(mem, src, sz);
    80001492:	8626                	mv	a2,s1
    80001494:	85ce                	mv	a1,s3
    80001496:	854a                	mv	a0,s2
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	95a080e7          	jalr	-1702(ra) # 80000df2 <memmove>
}
    800014a0:	70a2                	ld	ra,40(sp)
    800014a2:	7402                	ld	s0,32(sp)
    800014a4:	64e2                	ld	s1,24(sp)
    800014a6:	6942                	ld	s2,16(sp)
    800014a8:	69a2                	ld	s3,8(sp)
    800014aa:	6a02                	ld	s4,0(sp)
    800014ac:	6145                	addi	sp,sp,48
    800014ae:	8082                	ret
    panic("inituvm: more than a page");
    800014b0:	00007517          	auipc	a0,0x7
    800014b4:	cb050513          	addi	a0,a0,-848 # 80008160 <digits+0x108>
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	140080e7          	jalr	320(ra) # 800005f8 <panic>

00000000800014c0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014c0:	1101                	addi	sp,sp,-32
    800014c2:	ec06                	sd	ra,24(sp)
    800014c4:	e822                	sd	s0,16(sp)
    800014c6:	e426                	sd	s1,8(sp)
    800014c8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014ca:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014cc:	00b67d63          	bgeu	a2,a1,800014e6 <uvmdealloc+0x26>
    800014d0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014d2:	6785                	lui	a5,0x1
    800014d4:	17fd                	addi	a5,a5,-1
    800014d6:	00f60733          	add	a4,a2,a5
    800014da:	767d                	lui	a2,0xfffff
    800014dc:	8f71                	and	a4,a4,a2
    800014de:	97ae                	add	a5,a5,a1
    800014e0:	8ff1                	and	a5,a5,a2
    800014e2:	00f76863          	bltu	a4,a5,800014f2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014e6:	8526                	mv	a0,s1
    800014e8:	60e2                	ld	ra,24(sp)
    800014ea:	6442                	ld	s0,16(sp)
    800014ec:	64a2                	ld	s1,8(sp)
    800014ee:	6105                	addi	sp,sp,32
    800014f0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014f2:	8f99                	sub	a5,a5,a4
    800014f4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014f6:	4685                	li	a3,1
    800014f8:	0007861b          	sext.w	a2,a5
    800014fc:	85ba                	mv	a1,a4
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	e5e080e7          	jalr	-418(ra) # 8000135c <uvmunmap>
    80001506:	b7c5                	j	800014e6 <uvmdealloc+0x26>

0000000080001508 <uvmalloc>:
  if(newsz < oldsz)
    80001508:	0ab66163          	bltu	a2,a1,800015aa <uvmalloc+0xa2>
{
    8000150c:	7139                	addi	sp,sp,-64
    8000150e:	fc06                	sd	ra,56(sp)
    80001510:	f822                	sd	s0,48(sp)
    80001512:	f426                	sd	s1,40(sp)
    80001514:	f04a                	sd	s2,32(sp)
    80001516:	ec4e                	sd	s3,24(sp)
    80001518:	e852                	sd	s4,16(sp)
    8000151a:	e456                	sd	s5,8(sp)
    8000151c:	0080                	addi	s0,sp,64
    8000151e:	8aaa                	mv	s5,a0
    80001520:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001522:	6985                	lui	s3,0x1
    80001524:	19fd                	addi	s3,s3,-1
    80001526:	95ce                	add	a1,a1,s3
    80001528:	79fd                	lui	s3,0xfffff
    8000152a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152e:	08c9f063          	bgeu	s3,a2,800015ae <uvmalloc+0xa6>
    80001532:	894e                	mv	s2,s3
    mem = kalloc();
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	672080e7          	jalr	1650(ra) # 80000ba6 <kalloc>
    8000153c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000153e:	c51d                	beqz	a0,8000156c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001540:	6605                	lui	a2,0x1
    80001542:	4581                	li	a1,0
    80001544:	00000097          	auipc	ra,0x0
    80001548:	84e080e7          	jalr	-1970(ra) # 80000d92 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000154c:	4779                	li	a4,30
    8000154e:	86a6                	mv	a3,s1
    80001550:	6605                	lui	a2,0x1
    80001552:	85ca                	mv	a1,s2
    80001554:	8556                	mv	a0,s5
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	c6e080e7          	jalr	-914(ra) # 800011c4 <mappages>
    8000155e:	e905                	bnez	a0,8000158e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001560:	6785                	lui	a5,0x1
    80001562:	993e                	add	s2,s2,a5
    80001564:	fd4968e3          	bltu	s2,s4,80001534 <uvmalloc+0x2c>
  return newsz;
    80001568:	8552                	mv	a0,s4
    8000156a:	a809                	j	8000157c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000156c:	864e                	mv	a2,s3
    8000156e:	85ca                	mv	a1,s2
    80001570:	8556                	mv	a0,s5
    80001572:	00000097          	auipc	ra,0x0
    80001576:	f4e080e7          	jalr	-178(ra) # 800014c0 <uvmdealloc>
      return 0;
    8000157a:	4501                	li	a0,0
}
    8000157c:	70e2                	ld	ra,56(sp)
    8000157e:	7442                	ld	s0,48(sp)
    80001580:	74a2                	ld	s1,40(sp)
    80001582:	7902                	ld	s2,32(sp)
    80001584:	69e2                	ld	s3,24(sp)
    80001586:	6a42                	ld	s4,16(sp)
    80001588:	6aa2                	ld	s5,8(sp)
    8000158a:	6121                	addi	sp,sp,64
    8000158c:	8082                	ret
      kfree(mem);
    8000158e:	8526                	mv	a0,s1
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	51a080e7          	jalr	1306(ra) # 80000aaa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001598:	864e                	mv	a2,s3
    8000159a:	85ca                	mv	a1,s2
    8000159c:	8556                	mv	a0,s5
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	f22080e7          	jalr	-222(ra) # 800014c0 <uvmdealloc>
      return 0;
    800015a6:	4501                	li	a0,0
    800015a8:	bfd1                	j	8000157c <uvmalloc+0x74>
    return oldsz;
    800015aa:	852e                	mv	a0,a1
}
    800015ac:	8082                	ret
  return newsz;
    800015ae:	8532                	mv	a0,a2
    800015b0:	b7f1                	j	8000157c <uvmalloc+0x74>

00000000800015b2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b2:	7179                	addi	sp,sp,-48
    800015b4:	f406                	sd	ra,40(sp)
    800015b6:	f022                	sd	s0,32(sp)
    800015b8:	ec26                	sd	s1,24(sp)
    800015ba:	e84a                	sd	s2,16(sp)
    800015bc:	e44e                	sd	s3,8(sp)
    800015be:	e052                	sd	s4,0(sp)
    800015c0:	1800                	addi	s0,sp,48
    800015c2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c4:	84aa                	mv	s1,a0
    800015c6:	6905                	lui	s2,0x1
    800015c8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ca:	4985                	li	s3,1
    800015cc:	a821                	j	800015e4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ce:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015d0:	0532                	slli	a0,a0,0xc
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	fe0080e7          	jalr	-32(ra) # 800015b2 <freewalk>
      pagetable[i] = 0;
    800015da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015de:	04a1                	addi	s1,s1,8
    800015e0:	03248163          	beq	s1,s2,80001602 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015e4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e6:	00f57793          	andi	a5,a0,15
    800015ea:	ff3782e3          	beq	a5,s3,800015ce <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ee:	8905                	andi	a0,a0,1
    800015f0:	d57d                	beqz	a0,800015de <freewalk+0x2c>
      panic("freewalk: leaf");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	b8e50513          	addi	a0,a0,-1138 # 80008180 <digits+0x128>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	ffe080e7          	jalr	-2(ra) # 800005f8 <panic>
    }
  }
  kfree((void*)pagetable);
    80001602:	8552                	mv	a0,s4
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	4a6080e7          	jalr	1190(ra) # 80000aaa <kfree>
}
    8000160c:	70a2                	ld	ra,40(sp)
    8000160e:	7402                	ld	s0,32(sp)
    80001610:	64e2                	ld	s1,24(sp)
    80001612:	6942                	ld	s2,16(sp)
    80001614:	69a2                	ld	s3,8(sp)
    80001616:	6a02                	ld	s4,0(sp)
    80001618:	6145                	addi	sp,sp,48
    8000161a:	8082                	ret

000000008000161c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000161c:	1101                	addi	sp,sp,-32
    8000161e:	ec06                	sd	ra,24(sp)
    80001620:	e822                	sd	s0,16(sp)
    80001622:	e426                	sd	s1,8(sp)
    80001624:	1000                	addi	s0,sp,32
    80001626:	84aa                	mv	s1,a0
  if(sz > 0)
    80001628:	e999                	bnez	a1,8000163e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000162a:	8526                	mv	a0,s1
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	f86080e7          	jalr	-122(ra) # 800015b2 <freewalk>
}
    80001634:	60e2                	ld	ra,24(sp)
    80001636:	6442                	ld	s0,16(sp)
    80001638:	64a2                	ld	s1,8(sp)
    8000163a:	6105                	addi	sp,sp,32
    8000163c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000163e:	6605                	lui	a2,0x1
    80001640:	167d                	addi	a2,a2,-1
    80001642:	962e                	add	a2,a2,a1
    80001644:	4685                	li	a3,1
    80001646:	8231                	srli	a2,a2,0xc
    80001648:	4581                	li	a1,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	d12080e7          	jalr	-750(ra) # 8000135c <uvmunmap>
    80001652:	bfe1                	j	8000162a <uvmfree+0xe>

0000000080001654 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001654:	c679                	beqz	a2,80001722 <uvmcopy+0xce>
{
    80001656:	715d                	addi	sp,sp,-80
    80001658:	e486                	sd	ra,72(sp)
    8000165a:	e0a2                	sd	s0,64(sp)
    8000165c:	fc26                	sd	s1,56(sp)
    8000165e:	f84a                	sd	s2,48(sp)
    80001660:	f44e                	sd	s3,40(sp)
    80001662:	f052                	sd	s4,32(sp)
    80001664:	ec56                	sd	s5,24(sp)
    80001666:	e85a                	sd	s6,16(sp)
    80001668:	e45e                	sd	s7,8(sp)
    8000166a:	0880                	addi	s0,sp,80
    8000166c:	8b2a                	mv	s6,a0
    8000166e:	8aae                	mv	s5,a1
    80001670:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001672:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001674:	4601                	li	a2,0
    80001676:	85ce                	mv	a1,s3
    80001678:	855a                	mv	a0,s6
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	a04080e7          	jalr	-1532(ra) # 8000107e <walk>
    80001682:	c531                	beqz	a0,800016ce <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001684:	6118                	ld	a4,0(a0)
    80001686:	00177793          	andi	a5,a4,1
    8000168a:	cbb1                	beqz	a5,800016de <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000168c:	00a75593          	srli	a1,a4,0xa
    80001690:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001694:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	50e080e7          	jalr	1294(ra) # 80000ba6 <kalloc>
    800016a0:	892a                	mv	s2,a0
    800016a2:	c939                	beqz	a0,800016f8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016a4:	6605                	lui	a2,0x1
    800016a6:	85de                	mv	a1,s7
    800016a8:	fffff097          	auipc	ra,0xfffff
    800016ac:	74a080e7          	jalr	1866(ra) # 80000df2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b0:	8726                	mv	a4,s1
    800016b2:	86ca                	mv	a3,s2
    800016b4:	6605                	lui	a2,0x1
    800016b6:	85ce                	mv	a1,s3
    800016b8:	8556                	mv	a0,s5
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	b0a080e7          	jalr	-1270(ra) # 800011c4 <mappages>
    800016c2:	e515                	bnez	a0,800016ee <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016c4:	6785                	lui	a5,0x1
    800016c6:	99be                	add	s3,s3,a5
    800016c8:	fb49e6e3          	bltu	s3,s4,80001674 <uvmcopy+0x20>
    800016cc:	a081                	j	8000170c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ce:	00007517          	auipc	a0,0x7
    800016d2:	ac250513          	addi	a0,a0,-1342 # 80008190 <digits+0x138>
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	f22080e7          	jalr	-222(ra) # 800005f8 <panic>
      panic("uvmcopy: page not present");
    800016de:	00007517          	auipc	a0,0x7
    800016e2:	ad250513          	addi	a0,a0,-1326 # 800081b0 <digits+0x158>
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	f12080e7          	jalr	-238(ra) # 800005f8 <panic>
      kfree(mem);
    800016ee:	854a                	mv	a0,s2
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	3ba080e7          	jalr	954(ra) # 80000aaa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016f8:	4685                	li	a3,1
    800016fa:	00c9d613          	srli	a2,s3,0xc
    800016fe:	4581                	li	a1,0
    80001700:	8556                	mv	a0,s5
    80001702:	00000097          	auipc	ra,0x0
    80001706:	c5a080e7          	jalr	-934(ra) # 8000135c <uvmunmap>
  return -1;
    8000170a:	557d                	li	a0,-1
}
    8000170c:	60a6                	ld	ra,72(sp)
    8000170e:	6406                	ld	s0,64(sp)
    80001710:	74e2                	ld	s1,56(sp)
    80001712:	7942                	ld	s2,48(sp)
    80001714:	79a2                	ld	s3,40(sp)
    80001716:	7a02                	ld	s4,32(sp)
    80001718:	6ae2                	ld	s5,24(sp)
    8000171a:	6b42                	ld	s6,16(sp)
    8000171c:	6ba2                	ld	s7,8(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret
  return 0;
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret

0000000080001726 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001726:	1141                	addi	sp,sp,-16
    80001728:	e406                	sd	ra,8(sp)
    8000172a:	e022                	sd	s0,0(sp)
    8000172c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000172e:	4601                	li	a2,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	94e080e7          	jalr	-1714(ra) # 8000107e <walk>
  if(pte == 0)
    80001738:	c901                	beqz	a0,80001748 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173a:	611c                	ld	a5,0(a0)
    8000173c:	9bbd                	andi	a5,a5,-17
    8000173e:	e11c                	sd	a5,0(a0)
}
    80001740:	60a2                	ld	ra,8(sp)
    80001742:	6402                	ld	s0,0(sp)
    80001744:	0141                	addi	sp,sp,16
    80001746:	8082                	ret
    panic("uvmclear");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	a8850513          	addi	a0,a0,-1400 # 800081d0 <digits+0x178>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	ea8080e7          	jalr	-344(ra) # 800005f8 <panic>

0000000080001758 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001758:	c6bd                	beqz	a3,800017c6 <copyout+0x6e>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	e062                	sd	s8,0(sp)
    80001770:	0880                	addi	s0,sp,80
    80001772:	8b2a                	mv	s6,a0
    80001774:	8c2e                	mv	s8,a1
    80001776:	8a32                	mv	s4,a2
    80001778:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000177a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000177c:	6a85                	lui	s5,0x1
    8000177e:	a015                	j	800017a2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001780:	9562                	add	a0,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	85d2                	mv	a1,s4
    80001788:	41250533          	sub	a0,a0,s2
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	666080e7          	jalr	1638(ra) # 80000df2 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    src += n;
    80001798:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	97a080e7          	jalr	-1670(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f3e3          	bgeu	s3,s1,80001780 <copyout+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	b7c1                	j	80001780 <copyout+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyout+0x74>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017e4:	c6bd                	beqz	a3,80001852 <copyin+0x6e>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	e062                	sd	s8,0(sp)
    800017fc:	0880                	addi	s0,sp,80
    800017fe:	8b2a                	mv	s6,a0
    80001800:	8a2e                	mv	s4,a1
    80001802:	8c32                	mv	s8,a2
    80001804:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001806:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001808:	6a85                	lui	s5,0x1
    8000180a:	a015                	j	8000182e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000180c:	9562                	add	a0,a0,s8
    8000180e:	0004861b          	sext.w	a2,s1
    80001812:	412505b3          	sub	a1,a0,s2
    80001816:	8552                	mv	a0,s4
    80001818:	fffff097          	auipc	ra,0xfffff
    8000181c:	5da080e7          	jalr	1498(ra) # 80000df2 <memmove>

    len -= n;
    80001820:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001824:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001826:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000182a:	02098263          	beqz	s3,8000184e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000182e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001832:	85ca                	mv	a1,s2
    80001834:	855a                	mv	a0,s6
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	8ee080e7          	jalr	-1810(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000183e:	cd01                	beqz	a0,80001856 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001840:	418904b3          	sub	s1,s2,s8
    80001844:	94d6                	add	s1,s1,s5
    if(n > len)
    80001846:	fc99f3e3          	bgeu	s3,s1,8000180c <copyin+0x28>
    8000184a:	84ce                	mv	s1,s3
    8000184c:	b7c1                	j	8000180c <copyin+0x28>
  }
  return 0;
    8000184e:	4501                	li	a0,0
    80001850:	a021                	j	80001858 <copyin+0x74>
    80001852:	4501                	li	a0,0
}
    80001854:	8082                	ret
      return -1;
    80001856:	557d                	li	a0,-1
}
    80001858:	60a6                	ld	ra,72(sp)
    8000185a:	6406                	ld	s0,64(sp)
    8000185c:	74e2                	ld	s1,56(sp)
    8000185e:	7942                	ld	s2,48(sp)
    80001860:	79a2                	ld	s3,40(sp)
    80001862:	7a02                	ld	s4,32(sp)
    80001864:	6ae2                	ld	s5,24(sp)
    80001866:	6b42                	ld	s6,16(sp)
    80001868:	6ba2                	ld	s7,8(sp)
    8000186a:	6c02                	ld	s8,0(sp)
    8000186c:	6161                	addi	sp,sp,80
    8000186e:	8082                	ret

0000000080001870 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001870:	c6c5                	beqz	a3,80001918 <copyinstr+0xa8>
{
    80001872:	715d                	addi	sp,sp,-80
    80001874:	e486                	sd	ra,72(sp)
    80001876:	e0a2                	sd	s0,64(sp)
    80001878:	fc26                	sd	s1,56(sp)
    8000187a:	f84a                	sd	s2,48(sp)
    8000187c:	f44e                	sd	s3,40(sp)
    8000187e:	f052                	sd	s4,32(sp)
    80001880:	ec56                	sd	s5,24(sp)
    80001882:	e85a                	sd	s6,16(sp)
    80001884:	e45e                	sd	s7,8(sp)
    80001886:	0880                	addi	s0,sp,80
    80001888:	8a2a                	mv	s4,a0
    8000188a:	8b2e                	mv	s6,a1
    8000188c:	8bb2                	mv	s7,a2
    8000188e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001890:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001892:	6985                	lui	s3,0x1
    80001894:	a035                	j	800018c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001896:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000189a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000189c:	0017b793          	seqz	a5,a5
    800018a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018a4:	60a6                	ld	ra,72(sp)
    800018a6:	6406                	ld	s0,64(sp)
    800018a8:	74e2                	ld	s1,56(sp)
    800018aa:	7942                	ld	s2,48(sp)
    800018ac:	79a2                	ld	s3,40(sp)
    800018ae:	7a02                	ld	s4,32(sp)
    800018b0:	6ae2                	ld	s5,24(sp)
    800018b2:	6b42                	ld	s6,16(sp)
    800018b4:	6ba2                	ld	s7,8(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018be:	c8a9                	beqz	s1,80001910 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018c4:	85ca                	mv	a1,s2
    800018c6:	8552                	mv	a0,s4
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	85c080e7          	jalr	-1956(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800018d0:	c131                	beqz	a0,80001914 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018d2:	41790833          	sub	a6,s2,s7
    800018d6:	984e                	add	a6,a6,s3
    if(n > max)
    800018d8:	0104f363          	bgeu	s1,a6,800018de <copyinstr+0x6e>
    800018dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018de:	955e                	add	a0,a0,s7
    800018e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018e4:	fc080be3          	beqz	a6,800018ba <copyinstr+0x4a>
    800018e8:	985a                	add	a6,a6,s6
    800018ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ec:	41650633          	sub	a2,a0,s6
    800018f0:	14fd                	addi	s1,s1,-1
    800018f2:	9b26                	add	s6,s6,s1
    800018f4:	00f60733          	add	a4,a2,a5
    800018f8:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018fc:	df49                	beqz	a4,80001896 <copyinstr+0x26>
        *dst = *p;
    800018fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001902:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001906:	0785                	addi	a5,a5,1
    while(n > 0){
    80001908:	ff0796e3          	bne	a5,a6,800018f4 <copyinstr+0x84>
      dst++;
    8000190c:	8b42                	mv	s6,a6
    8000190e:	b775                	j	800018ba <copyinstr+0x4a>
    80001910:	4781                	li	a5,0
    80001912:	b769                	j	8000189c <copyinstr+0x2c>
      return -1;
    80001914:	557d                	li	a0,-1
    80001916:	b779                	j	800018a4 <copyinstr+0x34>
  int got_null = 0;
    80001918:	4781                	li	a5,0
  if(got_null){
    8000191a:	0017b793          	seqz	a5,a5
    8000191e:	40f00533          	neg	a0,a5
}
    80001922:	8082                	ret

0000000080001924 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001924:	1101                	addi	sp,sp,-32
    80001926:	ec06                	sd	ra,24(sp)
    80001928:	e822                	sd	s0,16(sp)
    8000192a:	e426                	sd	s1,8(sp)
    8000192c:	1000                	addi	s0,sp,32
    8000192e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	2ec080e7          	jalr	748(ra) # 80000c1c <holding>
    80001938:	c909                	beqz	a0,8000194a <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000193a:	749c                	ld	a5,40(s1)
    8000193c:	00978f63          	beq	a5,s1,8000195a <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001940:	60e2                	ld	ra,24(sp)
    80001942:	6442                	ld	s0,16(sp)
    80001944:	64a2                	ld	s1,8(sp)
    80001946:	6105                	addi	sp,sp,32
    80001948:	8082                	ret
    panic("wakeup1");
    8000194a:	00007517          	auipc	a0,0x7
    8000194e:	89650513          	addi	a0,a0,-1898 # 800081e0 <digits+0x188>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	ca6080e7          	jalr	-858(ra) # 800005f8 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000195a:	4c98                	lw	a4,24(s1)
    8000195c:	4785                	li	a5,1
    8000195e:	fef711e3          	bne	a4,a5,80001940 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001962:	4789                	li	a5,2
    80001964:	cc9c                	sw	a5,24(s1)
}
    80001966:	bfe9                	j	80001940 <wakeup1+0x1c>

0000000080001968 <procinit>:
{
    80001968:	715d                	addi	sp,sp,-80
    8000196a:	e486                	sd	ra,72(sp)
    8000196c:	e0a2                	sd	s0,64(sp)
    8000196e:	fc26                	sd	s1,56(sp)
    80001970:	f84a                	sd	s2,48(sp)
    80001972:	f44e                	sd	s3,40(sp)
    80001974:	f052                	sd	s4,32(sp)
    80001976:	ec56                	sd	s5,24(sp)
    80001978:	e85a                	sd	s6,16(sp)
    8000197a:	e45e                	sd	s7,8(sp)
    8000197c:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000197e:	00007597          	auipc	a1,0x7
    80001982:	86a58593          	addi	a1,a1,-1942 # 800081e8 <digits+0x190>
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	fca50513          	addi	a0,a0,-54 # 80011950 <pid_lock>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	278080e7          	jalr	632(ra) # 80000c06 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	00010917          	auipc	s2,0x10
    8000199a:	3d290913          	addi	s2,s2,978 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000199e:	00007b97          	auipc	s7,0x7
    800019a2:	852b8b93          	addi	s7,s7,-1966 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    800019a6:	8b4a                	mv	s6,s2
    800019a8:	00006a97          	auipc	s5,0x6
    800019ac:	658a8a93          	addi	s5,s5,1624 # 80008000 <etext>
    800019b0:	040009b7          	lui	s3,0x4000
    800019b4:	19fd                	addi	s3,s3,-1
    800019b6:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b8:	00016a17          	auipc	s4,0x16
    800019bc:	7b0a0a13          	addi	s4,s4,1968 # 80018168 <tickslock>
      initlock(&p->lock, "proc");
    800019c0:	85de                	mv	a1,s7
    800019c2:	854a                	mv	a0,s2
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	242080e7          	jalr	578(ra) # 80000c06 <initlock>
      char *pa = kalloc();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	1da080e7          	jalr	474(ra) # 80000ba6 <kalloc>
    800019d4:	85aa                	mv	a1,a0
      if(pa == 0)
    800019d6:	c929                	beqz	a0,80001a28 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019d8:	416904b3          	sub	s1,s2,s6
    800019dc:	8491                	srai	s1,s1,0x4
    800019de:	000ab783          	ld	a5,0(s5)
    800019e2:	02f484b3          	mul	s1,s1,a5
    800019e6:	2485                	addiw	s1,s1,1
    800019e8:	00d4949b          	slliw	s1,s1,0xd
    800019ec:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f0:	4699                	li	a3,6
    800019f2:	6605                	lui	a2,0x1
    800019f4:	8526                	mv	a0,s1
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	85c080e7          	jalr	-1956(ra) # 80001252 <kvmmap>
      p->kstack = va;
    800019fe:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a02:	19090913          	addi	s2,s2,400
    80001a06:	fb491de3          	bne	s2,s4,800019c0 <procinit+0x58>
  kvminithart();
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	650080e7          	jalr	1616(ra) # 8000105a <kvminithart>
}
    80001a12:	60a6                	ld	ra,72(sp)
    80001a14:	6406                	ld	s0,64(sp)
    80001a16:	74e2                	ld	s1,56(sp)
    80001a18:	7942                	ld	s2,48(sp)
    80001a1a:	79a2                	ld	s3,40(sp)
    80001a1c:	7a02                	ld	s4,32(sp)
    80001a1e:	6ae2                	ld	s5,24(sp)
    80001a20:	6b42                	ld	s6,16(sp)
    80001a22:	6ba2                	ld	s7,8(sp)
    80001a24:	6161                	addi	sp,sp,80
    80001a26:	8082                	ret
        panic("kalloc");
    80001a28:	00006517          	auipc	a0,0x6
    80001a2c:	7d050513          	addi	a0,a0,2000 # 800081f8 <digits+0x1a0>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	bc8080e7          	jalr	-1080(ra) # 800005f8 <panic>

0000000080001a38 <cpuid>:
{
    80001a38:	1141                	addi	sp,sp,-16
    80001a3a:	e422                	sd	s0,8(sp)
    80001a3c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a3e:	8512                	mv	a0,tp
}
    80001a40:	2501                	sext.w	a0,a0
    80001a42:	6422                	ld	s0,8(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret

0000000080001a48 <mycpu>:
mycpu(void) {
    80001a48:	1141                	addi	sp,sp,-16
    80001a4a:	e422                	sd	s0,8(sp)
    80001a4c:	0800                	addi	s0,sp,16
    80001a4e:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a50:	2781                	sext.w	a5,a5
    80001a52:	079e                	slli	a5,a5,0x7
}
    80001a54:	00010517          	auipc	a0,0x10
    80001a58:	f1450513          	addi	a0,a0,-236 # 80011968 <cpus>
    80001a5c:	953e                	add	a0,a0,a5
    80001a5e:	6422                	ld	s0,8(sp)
    80001a60:	0141                	addi	sp,sp,16
    80001a62:	8082                	ret

0000000080001a64 <myproc>:
myproc(void) {
    80001a64:	1101                	addi	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	1000                	addi	s0,sp,32
  push_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	1dc080e7          	jalr	476(ra) # 80000c4a <push_off>
    80001a76:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a78:	2781                	sext.w	a5,a5
    80001a7a:	079e                	slli	a5,a5,0x7
    80001a7c:	00010717          	auipc	a4,0x10
    80001a80:	ed470713          	addi	a4,a4,-300 # 80011950 <pid_lock>
    80001a84:	97ba                	add	a5,a5,a4
    80001a86:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	262080e7          	jalr	610(ra) # 80000cea <pop_off>
}
    80001a90:	8526                	mv	a0,s1
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6105                	addi	sp,sp,32
    80001a9a:	8082                	ret

0000000080001a9c <forkret>:
{
    80001a9c:	1141                	addi	sp,sp,-16
    80001a9e:	e406                	sd	ra,8(sp)
    80001aa0:	e022                	sd	s0,0(sp)
    80001aa2:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	fc0080e7          	jalr	-64(ra) # 80001a64 <myproc>
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	29e080e7          	jalr	670(ra) # 80000d4a <release>
  if (first) {
    80001ab4:	00007797          	auipc	a5,0x7
    80001ab8:	dac7a783          	lw	a5,-596(a5) # 80008860 <first.1672>
    80001abc:	eb89                	bnez	a5,80001ace <forkret+0x32>
  usertrapret();
    80001abe:	00001097          	auipc	ra,0x1
    80001ac2:	c72080e7          	jalr	-910(ra) # 80002730 <usertrapret>
}
    80001ac6:	60a2                	ld	ra,8(sp)
    80001ac8:	6402                	ld	s0,0(sp)
    80001aca:	0141                	addi	sp,sp,16
    80001acc:	8082                	ret
    first = 0;
    80001ace:	00007797          	auipc	a5,0x7
    80001ad2:	d807a923          	sw	zero,-622(a5) # 80008860 <first.1672>
    fsinit(ROOTDEV);
    80001ad6:	4505                	li	a0,1
    80001ad8:	00002097          	auipc	ra,0x2
    80001adc:	a7e080e7          	jalr	-1410(ra) # 80003556 <fsinit>
    80001ae0:	bff9                	j	80001abe <forkret+0x22>

0000000080001ae2 <allocpid>:
allocpid() {
    80001ae2:	1101                	addi	sp,sp,-32
    80001ae4:	ec06                	sd	ra,24(sp)
    80001ae6:	e822                	sd	s0,16(sp)
    80001ae8:	e426                	sd	s1,8(sp)
    80001aea:	e04a                	sd	s2,0(sp)
    80001aec:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aee:	00010917          	auipc	s2,0x10
    80001af2:	e6290913          	addi	s2,s2,-414 # 80011950 <pid_lock>
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	19e080e7          	jalr	414(ra) # 80000c96 <acquire>
  pid = nextpid;
    80001b00:	00007797          	auipc	a5,0x7
    80001b04:	d6478793          	addi	a5,a5,-668 # 80008864 <nextpid>
    80001b08:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b0a:	0014871b          	addiw	a4,s1,1
    80001b0e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b10:	854a                	mv	a0,s2
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	238080e7          	jalr	568(ra) # 80000d4a <release>
}
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	60e2                	ld	ra,24(sp)
    80001b1e:	6442                	ld	s0,16(sp)
    80001b20:	64a2                	ld	s1,8(sp)
    80001b22:	6902                	ld	s2,0(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret

0000000080001b28 <proc_pagetable>:
{
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	8ea080e7          	jalr	-1814(ra) # 80001420 <uvmcreate>
    80001b3e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b40:	c121                	beqz	a0,80001b80 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b42:	4729                	li	a4,10
    80001b44:	00005697          	auipc	a3,0x5
    80001b48:	4bc68693          	addi	a3,a3,1212 # 80007000 <_trampoline>
    80001b4c:	6605                	lui	a2,0x1
    80001b4e:	040005b7          	lui	a1,0x4000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b2                	slli	a1,a1,0xc
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	66e080e7          	jalr	1646(ra) # 800011c4 <mappages>
    80001b5e:	02054863          	bltz	a0,80001b8e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b62:	4719                	li	a4,6
    80001b64:	05893683          	ld	a3,88(s2)
    80001b68:	6605                	lui	a2,0x1
    80001b6a:	020005b7          	lui	a1,0x2000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b6                	slli	a1,a1,0xd
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	650080e7          	jalr	1616(ra) # 800011c4 <mappages>
    80001b7c:	02054163          	bltz	a0,80001b9e <proc_pagetable+0x76>
}
    80001b80:	8526                	mv	a0,s1
    80001b82:	60e2                	ld	ra,24(sp)
    80001b84:	6442                	ld	s0,16(sp)
    80001b86:	64a2                	ld	s1,8(sp)
    80001b88:	6902                	ld	s2,0(sp)
    80001b8a:	6105                	addi	sp,sp,32
    80001b8c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b8e:	4581                	li	a1,0
    80001b90:	8526                	mv	a0,s1
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	a8a080e7          	jalr	-1398(ra) # 8000161c <uvmfree>
    return 0;
    80001b9a:	4481                	li	s1,0
    80001b9c:	b7d5                	j	80001b80 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	8526                	mv	a0,s1
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	7b0080e7          	jalr	1968(ra) # 8000135c <uvmunmap>
    uvmfree(pagetable, 0);
    80001bb4:	4581                	li	a1,0
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	a64080e7          	jalr	-1436(ra) # 8000161c <uvmfree>
    return 0;
    80001bc0:	4481                	li	s1,0
    80001bc2:	bf7d                	j	80001b80 <proc_pagetable+0x58>

0000000080001bc4 <proc_freepagetable>:
{
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	e04a                	sd	s2,0(sp)
    80001bce:	1000                	addi	s0,sp,32
    80001bd0:	84aa                	mv	s1,a0
    80001bd2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bd4:	4681                	li	a3,0
    80001bd6:	4605                	li	a2,1
    80001bd8:	040005b7          	lui	a1,0x4000
    80001bdc:	15fd                	addi	a1,a1,-1
    80001bde:	05b2                	slli	a1,a1,0xc
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	77c080e7          	jalr	1916(ra) # 8000135c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001be8:	4681                	li	a3,0
    80001bea:	4605                	li	a2,1
    80001bec:	020005b7          	lui	a1,0x2000
    80001bf0:	15fd                	addi	a1,a1,-1
    80001bf2:	05b6                	slli	a1,a1,0xd
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	766080e7          	jalr	1894(ra) # 8000135c <uvmunmap>
  uvmfree(pagetable, sz);
    80001bfe:	85ca                	mv	a1,s2
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	a1a080e7          	jalr	-1510(ra) # 8000161c <uvmfree>
}
    80001c0a:	60e2                	ld	ra,24(sp)
    80001c0c:	6442                	ld	s0,16(sp)
    80001c0e:	64a2                	ld	s1,8(sp)
    80001c10:	6902                	ld	s2,0(sp)
    80001c12:	6105                	addi	sp,sp,32
    80001c14:	8082                	ret

0000000080001c16 <freeproc>:
{
    80001c16:	1101                	addi	sp,sp,-32
    80001c18:	ec06                	sd	ra,24(sp)
    80001c1a:	e822                	sd	s0,16(sp)
    80001c1c:	e426                	sd	s1,8(sp)
    80001c1e:	1000                	addi	s0,sp,32
    80001c20:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c22:	6d28                	ld	a0,88(a0)
    80001c24:	c509                	beqz	a0,80001c2e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	e84080e7          	jalr	-380(ra) # 80000aaa <kfree>
  if(p->alarm_trapframe)
    80001c2e:	1884b503          	ld	a0,392(s1)
    80001c32:	c509                	beqz	a0,80001c3c <freeproc+0x26>
    kfree((void*)p->alarm_trapframe);
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	e76080e7          	jalr	-394(ra) # 80000aaa <kfree>
  p->trapframe = 0;
    80001c3c:	0404bc23          	sd	zero,88(s1)
  p->alarm_trapframe = 0;
    80001c40:	1804b423          	sd	zero,392(s1)
  if(p->pagetable)
    80001c44:	68a8                	ld	a0,80(s1)
    80001c46:	c511                	beqz	a0,80001c52 <freeproc+0x3c>
    proc_freepagetable(p->pagetable, p->sz);
    80001c48:	64ac                	ld	a1,72(s1)
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	f7a080e7          	jalr	-134(ra) # 80001bc4 <proc_freepagetable>
  p->pagetable = 0;
    80001c52:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c56:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c5a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c5e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c62:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c66:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c6a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c6e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c72:	0004ac23          	sw	zero,24(s1)
  p->interval = 0;
    80001c76:	1604b423          	sd	zero,360(s1)
  p->handler = 0;
    80001c7a:	1604b823          	sd	zero,368(s1)
  p->ticks = 0;
    80001c7e:	1604bc23          	sd	zero,376(s1)
  p->is_alarm = 0;
    80001c82:	1804b023          	sd	zero,384(s1)
}
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6105                	addi	sp,sp,32
    80001c8e:	8082                	ret

0000000080001c90 <allocproc>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	e04a                	sd	s2,0(sp)
    80001c9a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9c:	00010497          	auipc	s1,0x10
    80001ca0:	0cc48493          	addi	s1,s1,204 # 80011d68 <proc>
    80001ca4:	00016917          	auipc	s2,0x16
    80001ca8:	4c490913          	addi	s2,s2,1220 # 80018168 <tickslock>
    acquire(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fe8080e7          	jalr	-24(ra) # 80000c96 <acquire>
    if(p->state == UNUSED) {
    80001cb6:	4c9c                	lw	a5,24(s1)
    80001cb8:	cf81                	beqz	a5,80001cd0 <allocproc+0x40>
      release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	08e080e7          	jalr	142(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc4:	19048493          	addi	s1,s1,400
    80001cc8:	ff2492e3          	bne	s1,s2,80001cac <allocproc+0x1c>
  return 0;
    80001ccc:	4481                	li	s1,0
    80001cce:	a0bd                	j	80001d3c <allocproc+0xac>
  p->pid = allocpid();
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	e12080e7          	jalr	-494(ra) # 80001ae2 <allocpid>
    80001cd8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	ecc080e7          	jalr	-308(ra) # 80000ba6 <kalloc>
    80001ce2:	892a                	mv	s2,a0
    80001ce4:	eca8                	sd	a0,88(s1)
    80001ce6:	c135                	beqz	a0,80001d4a <allocproc+0xba>
  if((p->alarm_trapframe = (struct trapframe *)kalloc()) == 0){
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	ebe080e7          	jalr	-322(ra) # 80000ba6 <kalloc>
    80001cf0:	892a                	mv	s2,a0
    80001cf2:	18a4b423          	sd	a0,392(s1)
    80001cf6:	c12d                	beqz	a0,80001d58 <allocproc+0xc8>
  p->is_alarm = 0;
    80001cf8:	1804b023          	sd	zero,384(s1)
  p->interval = 0;
    80001cfc:	1604b423          	sd	zero,360(s1)
  p->handler = 0;
    80001d00:	1604b823          	sd	zero,368(s1)
  p->ticks = 0;
    80001d04:	1604bc23          	sd	zero,376(s1)
  p->pagetable = proc_pagetable(p);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	e1e080e7          	jalr	-482(ra) # 80001b28 <proc_pagetable>
    80001d12:	892a                	mv	s2,a0
    80001d14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d16:	cd29                	beqz	a0,80001d70 <allocproc+0xe0>
  memset(&p->context, 0, sizeof(p->context));
    80001d18:	07000613          	li	a2,112
    80001d1c:	4581                	li	a1,0
    80001d1e:	06048513          	addi	a0,s1,96
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	070080e7          	jalr	112(ra) # 80000d92 <memset>
  p->context.ra = (uint64)forkret;
    80001d2a:	00000797          	auipc	a5,0x0
    80001d2e:	d7278793          	addi	a5,a5,-654 # 80001a9c <forkret>
    80001d32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d34:	60bc                	ld	a5,64(s1)
    80001d36:	6705                	lui	a4,0x1
    80001d38:	97ba                	add	a5,a5,a4
    80001d3a:	f4bc                	sd	a5,104(s1)
}
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6902                	ld	s2,0(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret
    release(&p->lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	ffe080e7          	jalr	-2(ra) # 80000d4a <release>
    return 0;
    80001d54:	84ca                	mv	s1,s2
    80001d56:	b7dd                	j	80001d3c <allocproc+0xac>
    freeproc(p);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	ebc080e7          	jalr	-324(ra) # 80001c16 <freeproc>
    release(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	fe6080e7          	jalr	-26(ra) # 80000d4a <release>
    return 0;
    80001d6c:	84ca                	mv	s1,s2
    80001d6e:	b7f9                	j	80001d3c <allocproc+0xac>
    freeproc(p);
    80001d70:	8526                	mv	a0,s1
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	ea4080e7          	jalr	-348(ra) # 80001c16 <freeproc>
    release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	fce080e7          	jalr	-50(ra) # 80000d4a <release>
    return 0;
    80001d84:	84ca                	mv	s1,s2
    80001d86:	bf5d                	j	80001d3c <allocproc+0xac>

0000000080001d88 <userinit>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	efe080e7          	jalr	-258(ra) # 80001c90 <allocproc>
    80001d9a:	84aa                	mv	s1,a0
  initproc = p;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	26a7be23          	sd	a0,636(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da4:	03400613          	li	a2,52
    80001da8:	00007597          	auipc	a1,0x7
    80001dac:	ac858593          	addi	a1,a1,-1336 # 80008870 <initcode>
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	69c080e7          	jalr	1692(ra) # 8000144e <uvminit>
  p->sz = PGSIZE;
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dbe:	6cb8                	ld	a4,88(s1)
    80001dc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc8:	4641                	li	a2,16
    80001dca:	00006597          	auipc	a1,0x6
    80001dce:	43658593          	addi	a1,a1,1078 # 80008200 <digits+0x1a8>
    80001dd2:	15848513          	addi	a0,s1,344
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	112080e7          	jalr	274(ra) # 80000ee8 <safestrcpy>
  p->cwd = namei("/");
    80001dde:	00006517          	auipc	a0,0x6
    80001de2:	43250513          	addi	a0,a0,1074 # 80008210 <digits+0x1b8>
    80001de6:	00002097          	auipc	ra,0x2
    80001dea:	198080e7          	jalr	408(ra) # 80003f7e <namei>
    80001dee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df2:	4789                	li	a5,2
    80001df4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	f52080e7          	jalr	-174(ra) # 80000d4a <release>
}
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <growproc>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	c4c080e7          	jalr	-948(ra) # 80001a64 <myproc>
    80001e20:	892a                	mv	s2,a0
  sz = p->sz;
    80001e22:	652c                	ld	a1,72(a0)
    80001e24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e28:	00904f63          	bgtz	s1,80001e46 <growproc+0x3c>
  } else if(n < 0){
    80001e2c:	0204cc63          	bltz	s1,80001e64 <growproc+0x5a>
  p->sz = sz;
    80001e30:	1602                	slli	a2,a2,0x20
    80001e32:	9201                	srli	a2,a2,0x20
    80001e34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e38:	4501                	li	a0,0
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e46:	9e25                	addw	a2,a2,s1
    80001e48:	1602                	slli	a2,a2,0x20
    80001e4a:	9201                	srli	a2,a2,0x20
    80001e4c:	1582                	slli	a1,a1,0x20
    80001e4e:	9181                	srli	a1,a1,0x20
    80001e50:	6928                	ld	a0,80(a0)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	6b6080e7          	jalr	1718(ra) # 80001508 <uvmalloc>
    80001e5a:	0005061b          	sext.w	a2,a0
    80001e5e:	fa69                	bnez	a2,80001e30 <growproc+0x26>
      return -1;
    80001e60:	557d                	li	a0,-1
    80001e62:	bfe1                	j	80001e3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e64:	9e25                	addw	a2,a2,s1
    80001e66:	1602                	slli	a2,a2,0x20
    80001e68:	9201                	srli	a2,a2,0x20
    80001e6a:	1582                	slli	a1,a1,0x20
    80001e6c:	9181                	srli	a1,a1,0x20
    80001e6e:	6928                	ld	a0,80(a0)
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	650080e7          	jalr	1616(ra) # 800014c0 <uvmdealloc>
    80001e78:	0005061b          	sext.w	a2,a0
    80001e7c:	bf55                	j	80001e30 <growproc+0x26>

0000000080001e7e <fork>:
{
    80001e7e:	7179                	addi	sp,sp,-48
    80001e80:	f406                	sd	ra,40(sp)
    80001e82:	f022                	sd	s0,32(sp)
    80001e84:	ec26                	sd	s1,24(sp)
    80001e86:	e84a                	sd	s2,16(sp)
    80001e88:	e44e                	sd	s3,8(sp)
    80001e8a:	e052                	sd	s4,0(sp)
    80001e8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	bd6080e7          	jalr	-1066(ra) # 80001a64 <myproc>
    80001e96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	df8080e7          	jalr	-520(ra) # 80001c90 <allocproc>
    80001ea0:	c175                	beqz	a0,80001f84 <fork+0x106>
    80001ea2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ea4:	04893603          	ld	a2,72(s2)
    80001ea8:	692c                	ld	a1,80(a0)
    80001eaa:	05093503          	ld	a0,80(s2)
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	7a6080e7          	jalr	1958(ra) # 80001654 <uvmcopy>
    80001eb6:	04054863          	bltz	a0,80001f06 <fork+0x88>
  np->sz = p->sz;
    80001eba:	04893783          	ld	a5,72(s2)
    80001ebe:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ec2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ec6:	05893683          	ld	a3,88(s2)
    80001eca:	87b6                	mv	a5,a3
    80001ecc:	0589b703          	ld	a4,88(s3)
    80001ed0:	12068693          	addi	a3,a3,288
    80001ed4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ed8:	6788                	ld	a0,8(a5)
    80001eda:	6b8c                	ld	a1,16(a5)
    80001edc:	6f90                	ld	a2,24(a5)
    80001ede:	01073023          	sd	a6,0(a4)
    80001ee2:	e708                	sd	a0,8(a4)
    80001ee4:	eb0c                	sd	a1,16(a4)
    80001ee6:	ef10                	sd	a2,24(a4)
    80001ee8:	02078793          	addi	a5,a5,32
    80001eec:	02070713          	addi	a4,a4,32
    80001ef0:	fed792e3          	bne	a5,a3,80001ed4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ef4:	0589b783          	ld	a5,88(s3)
    80001ef8:	0607b823          	sd	zero,112(a5)
    80001efc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f00:	15000a13          	li	s4,336
    80001f04:	a03d                	j	80001f32 <fork+0xb4>
    freeproc(np);
    80001f06:	854e                	mv	a0,s3
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	d0e080e7          	jalr	-754(ra) # 80001c16 <freeproc>
    release(&np->lock);
    80001f10:	854e                	mv	a0,s3
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	e38080e7          	jalr	-456(ra) # 80000d4a <release>
    return -1;
    80001f1a:	54fd                	li	s1,-1
    80001f1c:	a899                	j	80001f72 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f1e:	00002097          	auipc	ra,0x2
    80001f22:	6ec080e7          	jalr	1772(ra) # 8000460a <filedup>
    80001f26:	009987b3          	add	a5,s3,s1
    80001f2a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f2c:	04a1                	addi	s1,s1,8
    80001f2e:	01448763          	beq	s1,s4,80001f3c <fork+0xbe>
    if(p->ofile[i])
    80001f32:	009907b3          	add	a5,s2,s1
    80001f36:	6388                	ld	a0,0(a5)
    80001f38:	f17d                	bnez	a0,80001f1e <fork+0xa0>
    80001f3a:	bfcd                	j	80001f2c <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f3c:	15093503          	ld	a0,336(s2)
    80001f40:	00002097          	auipc	ra,0x2
    80001f44:	850080e7          	jalr	-1968(ra) # 80003790 <idup>
    80001f48:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f4c:	4641                	li	a2,16
    80001f4e:	15890593          	addi	a1,s2,344
    80001f52:	15898513          	addi	a0,s3,344
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	f92080e7          	jalr	-110(ra) # 80000ee8 <safestrcpy>
  pid = np->pid;
    80001f5e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f62:	4789                	li	a5,2
    80001f64:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f68:	854e                	mv	a0,s3
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	de0080e7          	jalr	-544(ra) # 80000d4a <release>
}
    80001f72:	8526                	mv	a0,s1
    80001f74:	70a2                	ld	ra,40(sp)
    80001f76:	7402                	ld	s0,32(sp)
    80001f78:	64e2                	ld	s1,24(sp)
    80001f7a:	6942                	ld	s2,16(sp)
    80001f7c:	69a2                	ld	s3,8(sp)
    80001f7e:	6a02                	ld	s4,0(sp)
    80001f80:	6145                	addi	sp,sp,48
    80001f82:	8082                	ret
    return -1;
    80001f84:	54fd                	li	s1,-1
    80001f86:	b7f5                	j	80001f72 <fork+0xf4>

0000000080001f88 <reparent>:
{
    80001f88:	7179                	addi	sp,sp,-48
    80001f8a:	f406                	sd	ra,40(sp)
    80001f8c:	f022                	sd	s0,32(sp)
    80001f8e:	ec26                	sd	s1,24(sp)
    80001f90:	e84a                	sd	s2,16(sp)
    80001f92:	e44e                	sd	s3,8(sp)
    80001f94:	e052                	sd	s4,0(sp)
    80001f96:	1800                	addi	s0,sp,48
    80001f98:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f9a:	00010497          	auipc	s1,0x10
    80001f9e:	dce48493          	addi	s1,s1,-562 # 80011d68 <proc>
      pp->parent = initproc;
    80001fa2:	00007a17          	auipc	s4,0x7
    80001fa6:	076a0a13          	addi	s4,s4,118 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001faa:	00016997          	auipc	s3,0x16
    80001fae:	1be98993          	addi	s3,s3,446 # 80018168 <tickslock>
    80001fb2:	a029                	j	80001fbc <reparent+0x34>
    80001fb4:	19048493          	addi	s1,s1,400
    80001fb8:	03348363          	beq	s1,s3,80001fde <reparent+0x56>
    if(pp->parent == p){
    80001fbc:	709c                	ld	a5,32(s1)
    80001fbe:	ff279be3          	bne	a5,s2,80001fb4 <reparent+0x2c>
      acquire(&pp->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cd2080e7          	jalr	-814(ra) # 80000c96 <acquire>
      pp->parent = initproc;
    80001fcc:	000a3783          	ld	a5,0(s4)
    80001fd0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d76080e7          	jalr	-650(ra) # 80000d4a <release>
    80001fdc:	bfe1                	j	80001fb4 <reparent+0x2c>
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6a02                	ld	s4,0(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret

0000000080001fee <scheduler>:
{
    80001fee:	715d                	addi	sp,sp,-80
    80001ff0:	e486                	sd	ra,72(sp)
    80001ff2:	e0a2                	sd	s0,64(sp)
    80001ff4:	fc26                	sd	s1,56(sp)
    80001ff6:	f84a                	sd	s2,48(sp)
    80001ff8:	f44e                	sd	s3,40(sp)
    80001ffa:	f052                	sd	s4,32(sp)
    80001ffc:	ec56                	sd	s5,24(sp)
    80001ffe:	e85a                	sd	s6,16(sp)
    80002000:	e45e                	sd	s7,8(sp)
    80002002:	e062                	sd	s8,0(sp)
    80002004:	0880                	addi	s0,sp,80
    80002006:	8792                	mv	a5,tp
  int id = r_tp();
    80002008:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000200a:	00779b13          	slli	s6,a5,0x7
    8000200e:	00010717          	auipc	a4,0x10
    80002012:	94270713          	addi	a4,a4,-1726 # 80011950 <pid_lock>
    80002016:	975a                	add	a4,a4,s6
    80002018:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000201c:	00010717          	auipc	a4,0x10
    80002020:	95470713          	addi	a4,a4,-1708 # 80011970 <cpus+0x8>
    80002024:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80002026:	4c0d                	li	s8,3
        c->proc = p;
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	00010a17          	auipc	s4,0x10
    8000202e:	926a0a13          	addi	s4,s4,-1754 # 80011950 <pid_lock>
    80002032:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002034:	00016997          	auipc	s3,0x16
    80002038:	13498993          	addi	s3,s3,308 # 80018168 <tickslock>
        found = 1;
    8000203c:	4b85                	li	s7,1
    8000203e:	a899                	j	80002094 <scheduler+0xa6>
        p->state = RUNNING;
    80002040:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002044:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80002048:	06048593          	addi	a1,s1,96
    8000204c:	855a                	mv	a0,s6
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	638080e7          	jalr	1592(ra) # 80002686 <swtch>
        c->proc = 0;
    80002056:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000205a:	8ade                	mv	s5,s7
      release(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	cec080e7          	jalr	-788(ra) # 80000d4a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002066:	19048493          	addi	s1,s1,400
    8000206a:	01348b63          	beq	s1,s3,80002080 <scheduler+0x92>
      acquire(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c26080e7          	jalr	-986(ra) # 80000c96 <acquire>
      if(p->state == RUNNABLE) {
    80002078:	4c9c                	lw	a5,24(s1)
    8000207a:	ff2791e3          	bne	a5,s2,8000205c <scheduler+0x6e>
    8000207e:	b7c9                	j	80002040 <scheduler+0x52>
    if(found == 0) {
    80002080:	000a9a63          	bnez	s5,80002094 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002084:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002088:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000208c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002090:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002094:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002098:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000209c:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020a0:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020a2:	00010497          	auipc	s1,0x10
    800020a6:	cc648493          	addi	s1,s1,-826 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800020aa:	4909                	li	s2,2
    800020ac:	b7c9                	j	8000206e <scheduler+0x80>

00000000800020ae <sched>:
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	9a8080e7          	jalr	-1624(ra) # 80001a64 <myproc>
    800020c4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b56080e7          	jalr	-1194(ra) # 80000c1c <holding>
    800020ce:	c93d                	beqz	a0,80002144 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020d2:	2781                	sext.w	a5,a5
    800020d4:	079e                	slli	a5,a5,0x7
    800020d6:	00010717          	auipc	a4,0x10
    800020da:	87a70713          	addi	a4,a4,-1926 # 80011950 <pid_lock>
    800020de:	97ba                	add	a5,a5,a4
    800020e0:	0907a703          	lw	a4,144(a5)
    800020e4:	4785                	li	a5,1
    800020e6:	06f71763          	bne	a4,a5,80002154 <sched+0xa6>
  if(p->state == RUNNING)
    800020ea:	4c98                	lw	a4,24(s1)
    800020ec:	478d                	li	a5,3
    800020ee:	06f70b63          	beq	a4,a5,80002164 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020f8:	efb5                	bnez	a5,80002174 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020fc:	00010917          	auipc	s2,0x10
    80002100:	85490913          	addi	s2,s2,-1964 # 80011950 <pid_lock>
    80002104:	2781                	sext.w	a5,a5
    80002106:	079e                	slli	a5,a5,0x7
    80002108:	97ca                	add	a5,a5,s2
    8000210a:	0947a983          	lw	s3,148(a5)
    8000210e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	00010597          	auipc	a1,0x10
    80002118:	85c58593          	addi	a1,a1,-1956 # 80011970 <cpus+0x8>
    8000211c:	95be                	add	a1,a1,a5
    8000211e:	06048513          	addi	a0,s1,96
    80002122:	00000097          	auipc	ra,0x0
    80002126:	564080e7          	jalr	1380(ra) # 80002686 <swtch>
    8000212a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	97ca                	add	a5,a5,s2
    80002132:	0937aa23          	sw	s3,148(a5)
}
    80002136:	70a2                	ld	ra,40(sp)
    80002138:	7402                	ld	s0,32(sp)
    8000213a:	64e2                	ld	s1,24(sp)
    8000213c:	6942                	ld	s2,16(sp)
    8000213e:	69a2                	ld	s3,8(sp)
    80002140:	6145                	addi	sp,sp,48
    80002142:	8082                	ret
    panic("sched p->lock");
    80002144:	00006517          	auipc	a0,0x6
    80002148:	0d450513          	addi	a0,a0,212 # 80008218 <digits+0x1c0>
    8000214c:	ffffe097          	auipc	ra,0xffffe
    80002150:	4ac080e7          	jalr	1196(ra) # 800005f8 <panic>
    panic("sched locks");
    80002154:	00006517          	auipc	a0,0x6
    80002158:	0d450513          	addi	a0,a0,212 # 80008228 <digits+0x1d0>
    8000215c:	ffffe097          	auipc	ra,0xffffe
    80002160:	49c080e7          	jalr	1180(ra) # 800005f8 <panic>
    panic("sched running");
    80002164:	00006517          	auipc	a0,0x6
    80002168:	0d450513          	addi	a0,a0,212 # 80008238 <digits+0x1e0>
    8000216c:	ffffe097          	auipc	ra,0xffffe
    80002170:	48c080e7          	jalr	1164(ra) # 800005f8 <panic>
    panic("sched interruptible");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	0d450513          	addi	a0,a0,212 # 80008248 <digits+0x1f0>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	47c080e7          	jalr	1148(ra) # 800005f8 <panic>

0000000080002184 <exit>:
{
    80002184:	7179                	addi	sp,sp,-48
    80002186:	f406                	sd	ra,40(sp)
    80002188:	f022                	sd	s0,32(sp)
    8000218a:	ec26                	sd	s1,24(sp)
    8000218c:	e84a                	sd	s2,16(sp)
    8000218e:	e44e                	sd	s3,8(sp)
    80002190:	e052                	sd	s4,0(sp)
    80002192:	1800                	addi	s0,sp,48
    80002194:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	8ce080e7          	jalr	-1842(ra) # 80001a64 <myproc>
    8000219e:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a0:	00007797          	auipc	a5,0x7
    800021a4:	e787b783          	ld	a5,-392(a5) # 80009018 <initproc>
    800021a8:	0d050493          	addi	s1,a0,208
    800021ac:	15050913          	addi	s2,a0,336
    800021b0:	02a79363          	bne	a5,a0,800021d6 <exit+0x52>
    panic("init exiting");
    800021b4:	00006517          	auipc	a0,0x6
    800021b8:	0ac50513          	addi	a0,a0,172 # 80008260 <digits+0x208>
    800021bc:	ffffe097          	auipc	ra,0xffffe
    800021c0:	43c080e7          	jalr	1084(ra) # 800005f8 <panic>
      fileclose(f);
    800021c4:	00002097          	auipc	ra,0x2
    800021c8:	498080e7          	jalr	1176(ra) # 8000465c <fileclose>
      p->ofile[fd] = 0;
    800021cc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d0:	04a1                	addi	s1,s1,8
    800021d2:	01248563          	beq	s1,s2,800021dc <exit+0x58>
    if(p->ofile[fd]){
    800021d6:	6088                	ld	a0,0(s1)
    800021d8:	f575                	bnez	a0,800021c4 <exit+0x40>
    800021da:	bfdd                	j	800021d0 <exit+0x4c>
  begin_op();
    800021dc:	00002097          	auipc	ra,0x2
    800021e0:	fae080e7          	jalr	-82(ra) # 8000418a <begin_op>
  iput(p->cwd);
    800021e4:	1509b503          	ld	a0,336(s3)
    800021e8:	00001097          	auipc	ra,0x1
    800021ec:	7a0080e7          	jalr	1952(ra) # 80003988 <iput>
  end_op();
    800021f0:	00002097          	auipc	ra,0x2
    800021f4:	01a080e7          	jalr	26(ra) # 8000420a <end_op>
  p->cwd = 0;
    800021f8:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021fc:	00007497          	auipc	s1,0x7
    80002200:	e1c48493          	addi	s1,s1,-484 # 80009018 <initproc>
    80002204:	6088                	ld	a0,0(s1)
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a90080e7          	jalr	-1392(ra) # 80000c96 <acquire>
  wakeup1(initproc);
    8000220e:	6088                	ld	a0,0(s1)
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	714080e7          	jalr	1812(ra) # 80001924 <wakeup1>
  release(&initproc->lock);
    80002218:	6088                	ld	a0,0(s1)
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	b30080e7          	jalr	-1232(ra) # 80000d4a <release>
  acquire(&p->lock);
    80002222:	854e                	mv	a0,s3
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a72080e7          	jalr	-1422(ra) # 80000c96 <acquire>
  struct proc *original_parent = p->parent;
    8000222c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002230:	854e                	mv	a0,s3
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	b18080e7          	jalr	-1256(ra) # 80000d4a <release>
  acquire(&original_parent->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a5a080e7          	jalr	-1446(ra) # 80000c96 <acquire>
  acquire(&p->lock);
    80002244:	854e                	mv	a0,s3
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a50080e7          	jalr	-1456(ra) # 80000c96 <acquire>
  reparent(p);
    8000224e:	854e                	mv	a0,s3
    80002250:	00000097          	auipc	ra,0x0
    80002254:	d38080e7          	jalr	-712(ra) # 80001f88 <reparent>
  wakeup1(original_parent);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	6ca080e7          	jalr	1738(ra) # 80001924 <wakeup1>
  p->xstate = status;
    80002262:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002266:	4791                	li	a5,4
    80002268:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	adc080e7          	jalr	-1316(ra) # 80000d4a <release>
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	e38080e7          	jalr	-456(ra) # 800020ae <sched>
  panic("zombie exit");
    8000227e:	00006517          	auipc	a0,0x6
    80002282:	ff250513          	addi	a0,a0,-14 # 80008270 <digits+0x218>
    80002286:	ffffe097          	auipc	ra,0xffffe
    8000228a:	372080e7          	jalr	882(ra) # 800005f8 <panic>

000000008000228e <yield>:
{
    8000228e:	1101                	addi	sp,sp,-32
    80002290:	ec06                	sd	ra,24(sp)
    80002292:	e822                	sd	s0,16(sp)
    80002294:	e426                	sd	s1,8(sp)
    80002296:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	7cc080e7          	jalr	1996(ra) # 80001a64 <myproc>
    800022a0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9f4080e7          	jalr	-1548(ra) # 80000c96 <acquire>
  p->state = RUNNABLE;
    800022aa:	4789                	li	a5,2
    800022ac:	cc9c                	sw	a5,24(s1)
  sched();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	e00080e7          	jalr	-512(ra) # 800020ae <sched>
  release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	a92080e7          	jalr	-1390(ra) # 80000d4a <release>
}
    800022c0:	60e2                	ld	ra,24(sp)
    800022c2:	6442                	ld	s0,16(sp)
    800022c4:	64a2                	ld	s1,8(sp)
    800022c6:	6105                	addi	sp,sp,32
    800022c8:	8082                	ret

00000000800022ca <sleep>:
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	89aa                	mv	s3,a0
    800022da:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	788080e7          	jalr	1928(ra) # 80001a64 <myproc>
    800022e4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022e6:	05250663          	beq	a0,s2,80002332 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9ac080e7          	jalr	-1620(ra) # 80000c96 <acquire>
    release(lk);
    800022f2:	854a                	mv	a0,s2
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	a56080e7          	jalr	-1450(ra) # 80000d4a <release>
  p->chan = chan;
    800022fc:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002300:	4785                	li	a5,1
    80002302:	cc9c                	sw	a5,24(s1)
  sched();
    80002304:	00000097          	auipc	ra,0x0
    80002308:	daa080e7          	jalr	-598(ra) # 800020ae <sched>
  p->chan = 0;
    8000230c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	a38080e7          	jalr	-1480(ra) # 80000d4a <release>
    acquire(lk);
    8000231a:	854a                	mv	a0,s2
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	97a080e7          	jalr	-1670(ra) # 80000c96 <acquire>
}
    80002324:	70a2                	ld	ra,40(sp)
    80002326:	7402                	ld	s0,32(sp)
    80002328:	64e2                	ld	s1,24(sp)
    8000232a:	6942                	ld	s2,16(sp)
    8000232c:	69a2                	ld	s3,8(sp)
    8000232e:	6145                	addi	sp,sp,48
    80002330:	8082                	ret
  p->chan = chan;
    80002332:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002336:	4785                	li	a5,1
    80002338:	cd1c                	sw	a5,24(a0)
  sched();
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	d74080e7          	jalr	-652(ra) # 800020ae <sched>
  p->chan = 0;
    80002342:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002346:	bff9                	j	80002324 <sleep+0x5a>

0000000080002348 <wait>:
{
    80002348:	715d                	addi	sp,sp,-80
    8000234a:	e486                	sd	ra,72(sp)
    8000234c:	e0a2                	sd	s0,64(sp)
    8000234e:	fc26                	sd	s1,56(sp)
    80002350:	f84a                	sd	s2,48(sp)
    80002352:	f44e                	sd	s3,40(sp)
    80002354:	f052                	sd	s4,32(sp)
    80002356:	ec56                	sd	s5,24(sp)
    80002358:	e85a                	sd	s6,16(sp)
    8000235a:	e45e                	sd	s7,8(sp)
    8000235c:	e062                	sd	s8,0(sp)
    8000235e:	0880                	addi	s0,sp,80
    80002360:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	702080e7          	jalr	1794(ra) # 80001a64 <myproc>
    8000236a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000236c:	8c2a                	mv	s8,a0
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	928080e7          	jalr	-1752(ra) # 80000c96 <acquire>
    havekids = 0;
    80002376:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002378:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000237a:	00016997          	auipc	s3,0x16
    8000237e:	dee98993          	addi	s3,s3,-530 # 80018168 <tickslock>
        havekids = 1;
    80002382:	4a85                	li	s5,1
    havekids = 0;
    80002384:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002386:	00010497          	auipc	s1,0x10
    8000238a:	9e248493          	addi	s1,s1,-1566 # 80011d68 <proc>
    8000238e:	a08d                	j	800023f0 <wait+0xa8>
          pid = np->pid;
    80002390:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002394:	000b0e63          	beqz	s6,800023b0 <wait+0x68>
    80002398:	4691                	li	a3,4
    8000239a:	03448613          	addi	a2,s1,52
    8000239e:	85da                	mv	a1,s6
    800023a0:	05093503          	ld	a0,80(s2)
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	3b4080e7          	jalr	948(ra) # 80001758 <copyout>
    800023ac:	02054263          	bltz	a0,800023d0 <wait+0x88>
          freeproc(np);
    800023b0:	8526                	mv	a0,s1
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	864080e7          	jalr	-1948(ra) # 80001c16 <freeproc>
          release(&np->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	98e080e7          	jalr	-1650(ra) # 80000d4a <release>
          release(&p->lock);
    800023c4:	854a                	mv	a0,s2
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	984080e7          	jalr	-1660(ra) # 80000d4a <release>
          return pid;
    800023ce:	a8a9                	j	80002428 <wait+0xe0>
            release(&np->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	978080e7          	jalr	-1672(ra) # 80000d4a <release>
            release(&p->lock);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	96e080e7          	jalr	-1682(ra) # 80000d4a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a089                	j	80002428 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023e8:	19048493          	addi	s1,s1,400
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xcc>
      if(np->parent == p){
    800023f0:	709c                	ld	a5,32(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xa0>
        acquire(&np->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	89e080e7          	jalr	-1890(ra) # 80000c96 <acquire>
        if(np->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94787e3          	beq	a5,s4,80002390 <wait+0x48>
        release(&np->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	942080e7          	jalr	-1726(ra) # 80000d4a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xa0>
    if(!havekids || p->killed){
    80002414:	c701                	beqz	a4,8000241c <wait+0xd4>
    80002416:	03092783          	lw	a5,48(s2)
    8000241a:	c785                	beqz	a5,80002442 <wait+0xfa>
      release(&p->lock);
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	92c080e7          	jalr	-1748(ra) # 80000d4a <release>
      return -1;
    80002426:	59fd                	li	s3,-1
}
    80002428:	854e                	mv	a0,s3
    8000242a:	60a6                	ld	ra,72(sp)
    8000242c:	6406                	ld	s0,64(sp)
    8000242e:	74e2                	ld	s1,56(sp)
    80002430:	7942                	ld	s2,48(sp)
    80002432:	79a2                	ld	s3,40(sp)
    80002434:	7a02                	ld	s4,32(sp)
    80002436:	6ae2                	ld	s5,24(sp)
    80002438:	6b42                	ld	s6,16(sp)
    8000243a:	6ba2                	ld	s7,8(sp)
    8000243c:	6c02                	ld	s8,0(sp)
    8000243e:	6161                	addi	sp,sp,80
    80002440:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002442:	85e2                	mv	a1,s8
    80002444:	854a                	mv	a0,s2
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	e84080e7          	jalr	-380(ra) # 800022ca <sleep>
    havekids = 0;
    8000244e:	bf1d                	j	80002384 <wait+0x3c>

0000000080002450 <wakeup>:
{
    80002450:	7139                	addi	sp,sp,-64
    80002452:	fc06                	sd	ra,56(sp)
    80002454:	f822                	sd	s0,48(sp)
    80002456:	f426                	sd	s1,40(sp)
    80002458:	f04a                	sd	s2,32(sp)
    8000245a:	ec4e                	sd	s3,24(sp)
    8000245c:	e852                	sd	s4,16(sp)
    8000245e:	e456                	sd	s5,8(sp)
    80002460:	0080                	addi	s0,sp,64
    80002462:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002464:	00010497          	auipc	s1,0x10
    80002468:	90448493          	addi	s1,s1,-1788 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000246c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000246e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002470:	00016917          	auipc	s2,0x16
    80002474:	cf890913          	addi	s2,s2,-776 # 80018168 <tickslock>
    80002478:	a821                	j	80002490 <wakeup+0x40>
      p->state = RUNNABLE;
    8000247a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	8ca080e7          	jalr	-1846(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002488:	19048493          	addi	s1,s1,400
    8000248c:	01248e63          	beq	s1,s2,800024a8 <wakeup+0x58>
    acquire(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	804080e7          	jalr	-2044(ra) # 80000c96 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000249a:	4c9c                	lw	a5,24(s1)
    8000249c:	ff3791e3          	bne	a5,s3,8000247e <wakeup+0x2e>
    800024a0:	749c                	ld	a5,40(s1)
    800024a2:	fd479ee3          	bne	a5,s4,8000247e <wakeup+0x2e>
    800024a6:	bfd1                	j	8000247a <wakeup+0x2a>
}
    800024a8:	70e2                	ld	ra,56(sp)
    800024aa:	7442                	ld	s0,48(sp)
    800024ac:	74a2                	ld	s1,40(sp)
    800024ae:	7902                	ld	s2,32(sp)
    800024b0:	69e2                	ld	s3,24(sp)
    800024b2:	6a42                	ld	s4,16(sp)
    800024b4:	6aa2                	ld	s5,8(sp)
    800024b6:	6121                	addi	sp,sp,64
    800024b8:	8082                	ret

00000000800024ba <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	1800                	addi	s0,sp,48
    800024c8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024ca:	00010497          	auipc	s1,0x10
    800024ce:	89e48493          	addi	s1,s1,-1890 # 80011d68 <proc>
    800024d2:	00016997          	auipc	s3,0x16
    800024d6:	c9698993          	addi	s3,s3,-874 # 80018168 <tickslock>
    acquire(&p->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7ba080e7          	jalr	1978(ra) # 80000c96 <acquire>
    if(p->pid == pid){
    800024e4:	5c9c                	lw	a5,56(s1)
    800024e6:	01278d63          	beq	a5,s2,80002500 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ea:	8526                	mv	a0,s1
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	85e080e7          	jalr	-1954(ra) # 80000d4a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f4:	19048493          	addi	s1,s1,400
    800024f8:	ff3491e3          	bne	s1,s3,800024da <kill+0x20>
  }
  return -1;
    800024fc:	557d                	li	a0,-1
    800024fe:	a829                	j	80002518 <kill+0x5e>
      p->killed = 1;
    80002500:	4785                	li	a5,1
    80002502:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002504:	4c98                	lw	a4,24(s1)
    80002506:	4785                	li	a5,1
    80002508:	00f70f63          	beq	a4,a5,80002526 <kill+0x6c>
      release(&p->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	83c080e7          	jalr	-1988(ra) # 80000d4a <release>
      return 0;
    80002516:	4501                	li	a0,0
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret
        p->state = RUNNABLE;
    80002526:	4789                	li	a5,2
    80002528:	cc9c                	sw	a5,24(s1)
    8000252a:	b7cd                	j	8000250c <kill+0x52>

000000008000252c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000252c:	7179                	addi	sp,sp,-48
    8000252e:	f406                	sd	ra,40(sp)
    80002530:	f022                	sd	s0,32(sp)
    80002532:	ec26                	sd	s1,24(sp)
    80002534:	e84a                	sd	s2,16(sp)
    80002536:	e44e                	sd	s3,8(sp)
    80002538:	e052                	sd	s4,0(sp)
    8000253a:	1800                	addi	s0,sp,48
    8000253c:	84aa                	mv	s1,a0
    8000253e:	892e                	mv	s2,a1
    80002540:	89b2                	mv	s3,a2
    80002542:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	520080e7          	jalr	1312(ra) # 80001a64 <myproc>
  if(user_dst){
    8000254c:	c08d                	beqz	s1,8000256e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000254e:	86d2                	mv	a3,s4
    80002550:	864e                	mv	a2,s3
    80002552:	85ca                	mv	a1,s2
    80002554:	6928                	ld	a0,80(a0)
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	202080e7          	jalr	514(ra) # 80001758 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000255e:	70a2                	ld	ra,40(sp)
    80002560:	7402                	ld	s0,32(sp)
    80002562:	64e2                	ld	s1,24(sp)
    80002564:	6942                	ld	s2,16(sp)
    80002566:	69a2                	ld	s3,8(sp)
    80002568:	6a02                	ld	s4,0(sp)
    8000256a:	6145                	addi	sp,sp,48
    8000256c:	8082                	ret
    memmove((char *)dst, src, len);
    8000256e:	000a061b          	sext.w	a2,s4
    80002572:	85ce                	mv	a1,s3
    80002574:	854a                	mv	a0,s2
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	87c080e7          	jalr	-1924(ra) # 80000df2 <memmove>
    return 0;
    8000257e:	8526                	mv	a0,s1
    80002580:	bff9                	j	8000255e <either_copyout+0x32>

0000000080002582 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002582:	7179                	addi	sp,sp,-48
    80002584:	f406                	sd	ra,40(sp)
    80002586:	f022                	sd	s0,32(sp)
    80002588:	ec26                	sd	s1,24(sp)
    8000258a:	e84a                	sd	s2,16(sp)
    8000258c:	e44e                	sd	s3,8(sp)
    8000258e:	e052                	sd	s4,0(sp)
    80002590:	1800                	addi	s0,sp,48
    80002592:	892a                	mv	s2,a0
    80002594:	84ae                	mv	s1,a1
    80002596:	89b2                	mv	s3,a2
    80002598:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	4ca080e7          	jalr	1226(ra) # 80001a64 <myproc>
  if(user_src){
    800025a2:	c08d                	beqz	s1,800025c4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a4:	86d2                	mv	a3,s4
    800025a6:	864e                	mv	a2,s3
    800025a8:	85ca                	mv	a1,s2
    800025aa:	6928                	ld	a0,80(a0)
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	238080e7          	jalr	568(ra) # 800017e4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b4:	70a2                	ld	ra,40(sp)
    800025b6:	7402                	ld	s0,32(sp)
    800025b8:	64e2                	ld	s1,24(sp)
    800025ba:	6942                	ld	s2,16(sp)
    800025bc:	69a2                	ld	s3,8(sp)
    800025be:	6a02                	ld	s4,0(sp)
    800025c0:	6145                	addi	sp,sp,48
    800025c2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c4:	000a061b          	sext.w	a2,s4
    800025c8:	85ce                	mv	a1,s3
    800025ca:	854a                	mv	a0,s2
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	826080e7          	jalr	-2010(ra) # 80000df2 <memmove>
    return 0;
    800025d4:	8526                	mv	a0,s1
    800025d6:	bff9                	j	800025b4 <either_copyin+0x32>

00000000800025d8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d8:	715d                	addi	sp,sp,-80
    800025da:	e486                	sd	ra,72(sp)
    800025dc:	e0a2                	sd	s0,64(sp)
    800025de:	fc26                	sd	s1,56(sp)
    800025e0:	f84a                	sd	s2,48(sp)
    800025e2:	f44e                	sd	s3,40(sp)
    800025e4:	f052                	sd	s4,32(sp)
    800025e6:	ec56                	sd	s5,24(sp)
    800025e8:	e85a                	sd	s6,16(sp)
    800025ea:	e45e                	sd	s7,8(sp)
    800025ec:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ee:	00006517          	auipc	a0,0x6
    800025f2:	af250513          	addi	a0,a0,-1294 # 800080e0 <digits+0x88>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	054080e7          	jalr	84(ra) # 8000064a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fe:	00010497          	auipc	s1,0x10
    80002602:	8c248493          	addi	s1,s1,-1854 # 80011ec0 <proc+0x158>
    80002606:	00016917          	auipc	s2,0x16
    8000260a:	cba90913          	addi	s2,s2,-838 # 800182c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002610:	00006997          	auipc	s3,0x6
    80002614:	c7098993          	addi	s3,s3,-912 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002618:	00006a97          	auipc	s5,0x6
    8000261c:	c70a8a93          	addi	s5,s5,-912 # 80008288 <digits+0x230>
    printf("\n");
    80002620:	00006a17          	auipc	s4,0x6
    80002624:	ac0a0a13          	addi	s4,s4,-1344 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002628:	00006b97          	auipc	s7,0x6
    8000262c:	c98b8b93          	addi	s7,s7,-872 # 800082c0 <states.1712>
    80002630:	a00d                	j	80002652 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002632:	ee06a583          	lw	a1,-288(a3)
    80002636:	8556                	mv	a0,s5
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	012080e7          	jalr	18(ra) # 8000064a <printf>
    printf("\n");
    80002640:	8552                	mv	a0,s4
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	008080e7          	jalr	8(ra) # 8000064a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264a:	19048493          	addi	s1,s1,400
    8000264e:	03248163          	beq	s1,s2,80002670 <procdump+0x98>
    if(p->state == UNUSED)
    80002652:	86a6                	mv	a3,s1
    80002654:	ec04a783          	lw	a5,-320(s1)
    80002658:	dbed                	beqz	a5,8000264a <procdump+0x72>
      state = "???";
    8000265a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265c:	fcfb6be3          	bltu	s6,a5,80002632 <procdump+0x5a>
    80002660:	1782                	slli	a5,a5,0x20
    80002662:	9381                	srli	a5,a5,0x20
    80002664:	078e                	slli	a5,a5,0x3
    80002666:	97de                	add	a5,a5,s7
    80002668:	6390                	ld	a2,0(a5)
    8000266a:	f661                	bnez	a2,80002632 <procdump+0x5a>
      state = "???";
    8000266c:	864e                	mv	a2,s3
    8000266e:	b7d1                	j	80002632 <procdump+0x5a>
  }
}
    80002670:	60a6                	ld	ra,72(sp)
    80002672:	6406                	ld	s0,64(sp)
    80002674:	74e2                	ld	s1,56(sp)
    80002676:	7942                	ld	s2,48(sp)
    80002678:	79a2                	ld	s3,40(sp)
    8000267a:	7a02                	ld	s4,32(sp)
    8000267c:	6ae2                	ld	s5,24(sp)
    8000267e:	6b42                	ld	s6,16(sp)
    80002680:	6ba2                	ld	s7,8(sp)
    80002682:	6161                	addi	sp,sp,80
    80002684:	8082                	ret

0000000080002686 <swtch>:
    80002686:	00153023          	sd	ra,0(a0)
    8000268a:	00253423          	sd	sp,8(a0)
    8000268e:	e900                	sd	s0,16(a0)
    80002690:	ed04                	sd	s1,24(a0)
    80002692:	03253023          	sd	s2,32(a0)
    80002696:	03353423          	sd	s3,40(a0)
    8000269a:	03453823          	sd	s4,48(a0)
    8000269e:	03553c23          	sd	s5,56(a0)
    800026a2:	05653023          	sd	s6,64(a0)
    800026a6:	05753423          	sd	s7,72(a0)
    800026aa:	05853823          	sd	s8,80(a0)
    800026ae:	05953c23          	sd	s9,88(a0)
    800026b2:	07a53023          	sd	s10,96(a0)
    800026b6:	07b53423          	sd	s11,104(a0)
    800026ba:	0005b083          	ld	ra,0(a1)
    800026be:	0085b103          	ld	sp,8(a1)
    800026c2:	6980                	ld	s0,16(a1)
    800026c4:	6d84                	ld	s1,24(a1)
    800026c6:	0205b903          	ld	s2,32(a1)
    800026ca:	0285b983          	ld	s3,40(a1)
    800026ce:	0305ba03          	ld	s4,48(a1)
    800026d2:	0385ba83          	ld	s5,56(a1)
    800026d6:	0405bb03          	ld	s6,64(a1)
    800026da:	0485bb83          	ld	s7,72(a1)
    800026de:	0505bc03          	ld	s8,80(a1)
    800026e2:	0585bc83          	ld	s9,88(a1)
    800026e6:	0605bd03          	ld	s10,96(a1)
    800026ea:	0685bd83          	ld	s11,104(a1)
    800026ee:	8082                	ret

00000000800026f0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e406                	sd	ra,8(sp)
    800026f4:	e022                	sd	s0,0(sp)
    800026f6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026f8:	00006597          	auipc	a1,0x6
    800026fc:	bf058593          	addi	a1,a1,-1040 # 800082e8 <states.1712+0x28>
    80002700:	00016517          	auipc	a0,0x16
    80002704:	a6850513          	addi	a0,a0,-1432 # 80018168 <tickslock>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4fe080e7          	jalr	1278(ra) # 80000c06 <initlock>
}
    80002710:	60a2                	ld	ra,8(sp)
    80002712:	6402                	ld	s0,0(sp)
    80002714:	0141                	addi	sp,sp,16
    80002716:	8082                	ret

0000000080002718 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002718:	1141                	addi	sp,sp,-16
    8000271a:	e422                	sd	s0,8(sp)
    8000271c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000271e:	00003797          	auipc	a5,0x3
    80002722:	5a278793          	addi	a5,a5,1442 # 80005cc0 <kernelvec>
    80002726:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272a:	6422                	ld	s0,8(sp)
    8000272c:	0141                	addi	sp,sp,16
    8000272e:	8082                	ret

0000000080002730 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002730:	1141                	addi	sp,sp,-16
    80002732:	e406                	sd	ra,8(sp)
    80002734:	e022                	sd	s0,0(sp)
    80002736:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	32c080e7          	jalr	812(ra) # 80001a64 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002740:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002744:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002746:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274a:	00005617          	auipc	a2,0x5
    8000274e:	8b660613          	addi	a2,a2,-1866 # 80007000 <_trampoline>
    80002752:	00005697          	auipc	a3,0x5
    80002756:	8ae68693          	addi	a3,a3,-1874 # 80007000 <_trampoline>
    8000275a:	8e91                	sub	a3,a3,a2
    8000275c:	040007b7          	lui	a5,0x4000
    80002760:	17fd                	addi	a5,a5,-1
    80002762:	07b2                	slli	a5,a5,0xc
    80002764:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002766:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000276c:	180026f3          	csrr	a3,satp
    80002770:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002772:	6d38                	ld	a4,88(a0)
    80002774:	6134                	ld	a3,64(a0)
    80002776:	6585                	lui	a1,0x1
    80002778:	96ae                	add	a3,a3,a1
    8000277a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000277c:	6d38                	ld	a4,88(a0)
    8000277e:	00000697          	auipc	a3,0x0
    80002782:	13868693          	addi	a3,a3,312 # 800028b6 <usertrap>
    80002786:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002788:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278a:	8692                	mv	a3,tp
    8000278c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000278e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002792:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002796:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000279e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a0:	6f18                	ld	a4,24(a4)
    800027a2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027a6:	692c                	ld	a1,80(a0)
    800027a8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027aa:	00005717          	auipc	a4,0x5
    800027ae:	8e670713          	addi	a4,a4,-1818 # 80007090 <userret>
    800027b2:	8f11                	sub	a4,a4,a2
    800027b4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027b6:	577d                	li	a4,-1
    800027b8:	177e                	slli	a4,a4,0x3f
    800027ba:	8dd9                	or	a1,a1,a4
    800027bc:	02000537          	lui	a0,0x2000
    800027c0:	157d                	addi	a0,a0,-1
    800027c2:	0536                	slli	a0,a0,0xd
    800027c4:	9782                	jalr	a5
}
    800027c6:	60a2                	ld	ra,8(sp)
    800027c8:	6402                	ld	s0,0(sp)
    800027ca:	0141                	addi	sp,sp,16
    800027cc:	8082                	ret

00000000800027ce <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ce:	1101                	addi	sp,sp,-32
    800027d0:	ec06                	sd	ra,24(sp)
    800027d2:	e822                	sd	s0,16(sp)
    800027d4:	e426                	sd	s1,8(sp)
    800027d6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027d8:	00016497          	auipc	s1,0x16
    800027dc:	99048493          	addi	s1,s1,-1648 # 80018168 <tickslock>
    800027e0:	8526                	mv	a0,s1
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	4b4080e7          	jalr	1204(ra) # 80000c96 <acquire>
  ticks++;
    800027ea:	00007517          	auipc	a0,0x7
    800027ee:	83650513          	addi	a0,a0,-1994 # 80009020 <ticks>
    800027f2:	411c                	lw	a5,0(a0)
    800027f4:	2785                	addiw	a5,a5,1
    800027f6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	c58080e7          	jalr	-936(ra) # 80002450 <wakeup>
  release(&tickslock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	548080e7          	jalr	1352(ra) # 80000d4a <release>
}
    8000280a:	60e2                	ld	ra,24(sp)
    8000280c:	6442                	ld	s0,16(sp)
    8000280e:	64a2                	ld	s1,8(sp)
    80002810:	6105                	addi	sp,sp,32
    80002812:	8082                	ret

0000000080002814 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002814:	1101                	addi	sp,sp,-32
    80002816:	ec06                	sd	ra,24(sp)
    80002818:	e822                	sd	s0,16(sp)
    8000281a:	e426                	sd	s1,8(sp)
    8000281c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000281e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002822:	00074d63          	bltz	a4,8000283c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002826:	57fd                	li	a5,-1
    80002828:	17fe                	slli	a5,a5,0x3f
    8000282a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000282c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000282e:	06f70363          	beq	a4,a5,80002894 <devintr+0x80>
  }
}
    80002832:	60e2                	ld	ra,24(sp)
    80002834:	6442                	ld	s0,16(sp)
    80002836:	64a2                	ld	s1,8(sp)
    80002838:	6105                	addi	sp,sp,32
    8000283a:	8082                	ret
     (scause & 0xff) == 9){
    8000283c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002840:	46a5                	li	a3,9
    80002842:	fed792e3          	bne	a5,a3,80002826 <devintr+0x12>
    int irq = plic_claim();
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	582080e7          	jalr	1410(ra) # 80005dc8 <plic_claim>
    8000284e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002850:	47a9                	li	a5,10
    80002852:	02f50763          	beq	a0,a5,80002880 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002856:	4785                	li	a5,1
    80002858:	02f50963          	beq	a0,a5,8000288a <devintr+0x76>
    return 1;
    8000285c:	4505                	li	a0,1
    } else if(irq){
    8000285e:	d8f1                	beqz	s1,80002832 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002860:	85a6                	mv	a1,s1
    80002862:	00006517          	auipc	a0,0x6
    80002866:	a8e50513          	addi	a0,a0,-1394 # 800082f0 <states.1712+0x30>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	de0080e7          	jalr	-544(ra) # 8000064a <printf>
      plic_complete(irq);
    80002872:	8526                	mv	a0,s1
    80002874:	00003097          	auipc	ra,0x3
    80002878:	578080e7          	jalr	1400(ra) # 80005dec <plic_complete>
    return 1;
    8000287c:	4505                	li	a0,1
    8000287e:	bf55                	j	80002832 <devintr+0x1e>
      uartintr();
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	1da080e7          	jalr	474(ra) # 80000a5a <uartintr>
    80002888:	b7ed                	j	80002872 <devintr+0x5e>
      virtio_disk_intr();
    8000288a:	00004097          	auipc	ra,0x4
    8000288e:	9fc080e7          	jalr	-1540(ra) # 80006286 <virtio_disk_intr>
    80002892:	b7c5                	j	80002872 <devintr+0x5e>
    if(cpuid() == 0){
    80002894:	fffff097          	auipc	ra,0xfffff
    80002898:	1a4080e7          	jalr	420(ra) # 80001a38 <cpuid>
    8000289c:	c901                	beqz	a0,800028ac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000289e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a4:	14479073          	csrw	sip,a5
    return 2;
    800028a8:	4509                	li	a0,2
    800028aa:	b761                	j	80002832 <devintr+0x1e>
      clockintr();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	f22080e7          	jalr	-222(ra) # 800027ce <clockintr>
    800028b4:	b7ed                	j	8000289e <devintr+0x8a>

00000000800028b6 <usertrap>:
{
    800028b6:	1101                	addi	sp,sp,-32
    800028b8:	ec06                	sd	ra,24(sp)
    800028ba:	e822                	sd	s0,16(sp)
    800028bc:	e426                	sd	s1,8(sp)
    800028be:	e04a                	sd	s2,0(sp)
    800028c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028c6:	1007f793          	andi	a5,a5,256
    800028ca:	e3ad                	bnez	a5,8000292c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028cc:	00003797          	auipc	a5,0x3
    800028d0:	3f478793          	addi	a5,a5,1012 # 80005cc0 <kernelvec>
    800028d4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	18c080e7          	jalr	396(ra) # 80001a64 <myproc>
    800028e0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	14102773          	csrr	a4,sepc
    800028e8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ea:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ee:	47a1                	li	a5,8
    800028f0:	04f71c63          	bne	a4,a5,80002948 <usertrap+0x92>
    if(p->killed)
    800028f4:	591c                	lw	a5,48(a0)
    800028f6:	e3b9                	bnez	a5,8000293c <usertrap+0x86>
    p->trapframe->epc += 4;
    800028f8:	6cb8                	ld	a4,88(s1)
    800028fa:	6f1c                	ld	a5,24(a4)
    800028fc:	0791                	addi	a5,a5,4
    800028fe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002900:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002904:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002908:	10079073          	csrw	sstatus,a5
    syscall();
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	32e080e7          	jalr	814(ra) # 80002c3a <syscall>
  if(p->killed)
    80002914:	589c                	lw	a5,48(s1)
    80002916:	e3d5                	bnez	a5,800029ba <usertrap+0x104>
  usertrapret();
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	e18080e7          	jalr	-488(ra) # 80002730 <usertrapret>
}
    80002920:	60e2                	ld	ra,24(sp)
    80002922:	6442                	ld	s0,16(sp)
    80002924:	64a2                	ld	s1,8(sp)
    80002926:	6902                	ld	s2,0(sp)
    80002928:	6105                	addi	sp,sp,32
    8000292a:	8082                	ret
    panic("usertrap: not from user mode");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	9e450513          	addi	a0,a0,-1564 # 80008310 <states.1712+0x50>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	cc4080e7          	jalr	-828(ra) # 800005f8 <panic>
      exit(-1);
    8000293c:	557d                	li	a0,-1
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	846080e7          	jalr	-1978(ra) # 80002184 <exit>
    80002946:	bf4d                	j	800028f8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	ecc080e7          	jalr	-308(ra) # 80002814 <devintr>
    80002950:	892a                	mv	s2,a0
    80002952:	c501                	beqz	a0,8000295a <usertrap+0xa4>
  if(p->killed)
    80002954:	589c                	lw	a5,48(s1)
    80002956:	c3a1                	beqz	a5,80002996 <usertrap+0xe0>
    80002958:	a815                	j	8000298c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295e:	5c90                	lw	a2,56(s1)
    80002960:	00006517          	auipc	a0,0x6
    80002964:	9d050513          	addi	a0,a0,-1584 # 80008330 <states.1712+0x70>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	ce2080e7          	jalr	-798(ra) # 8000064a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002974:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	9e850513          	addi	a0,a0,-1560 # 80008360 <states.1712+0xa0>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	cca080e7          	jalr	-822(ra) # 8000064a <printf>
    p->killed = 1;
    80002988:	4785                	li	a5,1
    8000298a:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000298c:	557d                	li	a0,-1
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	7f6080e7          	jalr	2038(ra) # 80002184 <exit>
  if(which_dev == 2) {
    80002996:	4789                	li	a5,2
    80002998:	f8f910e3          	bne	s2,a5,80002918 <usertrap+0x62>
    if(p->interval != 0) {
    8000299c:	1684b783          	ld	a5,360(s1)
    800029a0:	cb81                	beqz	a5,800029b0 <usertrap+0xfa>
      p->ticks += 1;
    800029a2:	1784b603          	ld	a2,376(s1)
    800029a6:	0605                	addi	a2,a2,1
    800029a8:	16c4bc23          	sd	a2,376(s1)
      if(p->ticks == p->interval && p->is_alarm == 0) {
    800029ac:	00c78963          	beq	a5,a2,800029be <usertrap+0x108>
    yield();
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	8de080e7          	jalr	-1826(ra) # 8000228e <yield>
    800029b8:	b785                	j	80002918 <usertrap+0x62>
  int which_dev = 0;
    800029ba:	4901                	li	s2,0
    800029bc:	bfc1                	j	8000298c <usertrap+0xd6>
      if(p->ticks == p->interval && p->is_alarm == 0) {
    800029be:	1804b783          	ld	a5,384(s1)
    800029c2:	f7fd                	bnez	a5,800029b0 <usertrap+0xfa>
        printf("timer intr :pid : %d, ticks: %d\n", p->pid, p->ticks);
    800029c4:	5c8c                	lw	a1,56(s1)
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	9ba50513          	addi	a0,a0,-1606 # 80008380 <states.1712+0xc0>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	c7c080e7          	jalr	-900(ra) # 8000064a <printf>
        memmove(p->alarm_trapframe, p->trapframe, sizeof(struct trapframe));
    800029d6:	12000613          	li	a2,288
    800029da:	6cac                	ld	a1,88(s1)
    800029dc:	1884b503          	ld	a0,392(s1)
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	412080e7          	jalr	1042(ra) # 80000df2 <memmove>
        p->trapframe->epc = p->handler;
    800029e8:	6cbc                	ld	a5,88(s1)
    800029ea:	1704b703          	ld	a4,368(s1)
    800029ee:	ef98                	sd	a4,24(a5)
        p->is_alarm = 1;
    800029f0:	4785                	li	a5,1
    800029f2:	18f4b023          	sd	a5,384(s1)
    800029f6:	bf6d                	j	800029b0 <usertrap+0xfa>

00000000800029f8 <kerneltrap>:
{
    800029f8:	7179                	addi	sp,sp,-48
    800029fa:	f406                	sd	ra,40(sp)
    800029fc:	f022                	sd	s0,32(sp)
    800029fe:	ec26                	sd	s1,24(sp)
    80002a00:	e84a                	sd	s2,16(sp)
    80002a02:	e44e                	sd	s3,8(sp)
    80002a04:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a12:	1004f793          	andi	a5,s1,256
    80002a16:	cb85                	beqz	a5,80002a46 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a1c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a1e:	ef85                	bnez	a5,80002a56 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	df4080e7          	jalr	-524(ra) # 80002814 <devintr>
    80002a28:	cd1d                	beqz	a0,80002a66 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2a:	4789                	li	a5,2
    80002a2c:	06f50a63          	beq	a0,a5,80002aa0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a30:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a34:	10049073          	csrw	sstatus,s1
}
    80002a38:	70a2                	ld	ra,40(sp)
    80002a3a:	7402                	ld	s0,32(sp)
    80002a3c:	64e2                	ld	s1,24(sp)
    80002a3e:	6942                	ld	s2,16(sp)
    80002a40:	69a2                	ld	s3,8(sp)
    80002a42:	6145                	addi	sp,sp,48
    80002a44:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	96250513          	addi	a0,a0,-1694 # 800083a8 <states.1712+0xe8>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	baa080e7          	jalr	-1110(ra) # 800005f8 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	97a50513          	addi	a0,a0,-1670 # 800083d0 <states.1712+0x110>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	b9a080e7          	jalr	-1126(ra) # 800005f8 <panic>
    printf("scause %p\n", scause);
    80002a66:	85ce                	mv	a1,s3
    80002a68:	00006517          	auipc	a0,0x6
    80002a6c:	98850513          	addi	a0,a0,-1656 # 800083f0 <states.1712+0x130>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	bda080e7          	jalr	-1062(ra) # 8000064a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a78:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a7c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	98050513          	addi	a0,a0,-1664 # 80008400 <states.1712+0x140>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	bc2080e7          	jalr	-1086(ra) # 8000064a <printf>
    panic("kerneltrap");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	98850513          	addi	a0,a0,-1656 # 80008418 <states.1712+0x158>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	b60080e7          	jalr	-1184(ra) # 800005f8 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	fc4080e7          	jalr	-60(ra) # 80001a64 <myproc>
    80002aa8:	d541                	beqz	a0,80002a30 <kerneltrap+0x38>
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	fba080e7          	jalr	-70(ra) # 80001a64 <myproc>
    80002ab2:	4d18                	lw	a4,24(a0)
    80002ab4:	478d                	li	a5,3
    80002ab6:	f6f71de3          	bne	a4,a5,80002a30 <kerneltrap+0x38>
    yield();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	7d4080e7          	jalr	2004(ra) # 8000228e <yield>
    80002ac2:	b7bd                	j	80002a30 <kerneltrap+0x38>

0000000080002ac4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ac4:	1101                	addi	sp,sp,-32
    80002ac6:	ec06                	sd	ra,24(sp)
    80002ac8:	e822                	sd	s0,16(sp)
    80002aca:	e426                	sd	s1,8(sp)
    80002acc:	1000                	addi	s0,sp,32
    80002ace:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	f94080e7          	jalr	-108(ra) # 80001a64 <myproc>
  switch (n) {
    80002ad8:	4795                	li	a5,5
    80002ada:	0497e163          	bltu	a5,s1,80002b1c <argraw+0x58>
    80002ade:	048a                	slli	s1,s1,0x2
    80002ae0:	00006717          	auipc	a4,0x6
    80002ae4:	97070713          	addi	a4,a4,-1680 # 80008450 <states.1712+0x190>
    80002ae8:	94ba                	add	s1,s1,a4
    80002aea:	409c                	lw	a5,0(s1)
    80002aec:	97ba                	add	a5,a5,a4
    80002aee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002af0:	6d3c                	ld	a5,88(a0)
    80002af2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret
    return p->trapframe->a1;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	7fa8                	ld	a0,120(a5)
    80002b02:	bfcd                	j	80002af4 <argraw+0x30>
    return p->trapframe->a2;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	63c8                	ld	a0,128(a5)
    80002b08:	b7f5                	j	80002af4 <argraw+0x30>
    return p->trapframe->a3;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	67c8                	ld	a0,136(a5)
    80002b0e:	b7dd                	j	80002af4 <argraw+0x30>
    return p->trapframe->a4;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	6bc8                	ld	a0,144(a5)
    80002b14:	b7c5                	j	80002af4 <argraw+0x30>
    return p->trapframe->a5;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	6fc8                	ld	a0,152(a5)
    80002b1a:	bfe9                	j	80002af4 <argraw+0x30>
  panic("argraw");
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	90c50513          	addi	a0,a0,-1780 # 80008428 <states.1712+0x168>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	ad4080e7          	jalr	-1324(ra) # 800005f8 <panic>

0000000080002b2c <fetchaddr>:
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	e04a                	sd	s2,0(sp)
    80002b36:	1000                	addi	s0,sp,32
    80002b38:	84aa                	mv	s1,a0
    80002b3a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	f28080e7          	jalr	-216(ra) # 80001a64 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b44:	653c                	ld	a5,72(a0)
    80002b46:	02f4f863          	bgeu	s1,a5,80002b76 <fetchaddr+0x4a>
    80002b4a:	00848713          	addi	a4,s1,8
    80002b4e:	02e7e663          	bltu	a5,a4,80002b7a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b52:	46a1                	li	a3,8
    80002b54:	8626                	mv	a2,s1
    80002b56:	85ca                	mv	a1,s2
    80002b58:	6928                	ld	a0,80(a0)
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	c8a080e7          	jalr	-886(ra) # 800017e4 <copyin>
    80002b62:	00a03533          	snez	a0,a0
    80002b66:	40a00533          	neg	a0,a0
}
    80002b6a:	60e2                	ld	ra,24(sp)
    80002b6c:	6442                	ld	s0,16(sp)
    80002b6e:	64a2                	ld	s1,8(sp)
    80002b70:	6902                	ld	s2,0(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret
    return -1;
    80002b76:	557d                	li	a0,-1
    80002b78:	bfcd                	j	80002b6a <fetchaddr+0x3e>
    80002b7a:	557d                	li	a0,-1
    80002b7c:	b7fd                	j	80002b6a <fetchaddr+0x3e>

0000000080002b7e <fetchstr>:
{
    80002b7e:	7179                	addi	sp,sp,-48
    80002b80:	f406                	sd	ra,40(sp)
    80002b82:	f022                	sd	s0,32(sp)
    80002b84:	ec26                	sd	s1,24(sp)
    80002b86:	e84a                	sd	s2,16(sp)
    80002b88:	e44e                	sd	s3,8(sp)
    80002b8a:	1800                	addi	s0,sp,48
    80002b8c:	892a                	mv	s2,a0
    80002b8e:	84ae                	mv	s1,a1
    80002b90:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	ed2080e7          	jalr	-302(ra) # 80001a64 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b9a:	86ce                	mv	a3,s3
    80002b9c:	864a                	mv	a2,s2
    80002b9e:	85a6                	mv	a1,s1
    80002ba0:	6928                	ld	a0,80(a0)
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	cce080e7          	jalr	-818(ra) # 80001870 <copyinstr>
  if(err < 0)
    80002baa:	00054763          	bltz	a0,80002bb8 <fetchstr+0x3a>
  return strlen(buf);
    80002bae:	8526                	mv	a0,s1
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	36a080e7          	jalr	874(ra) # 80000f1a <strlen>
}
    80002bb8:	70a2                	ld	ra,40(sp)
    80002bba:	7402                	ld	s0,32(sp)
    80002bbc:	64e2                	ld	s1,24(sp)
    80002bbe:	6942                	ld	s2,16(sp)
    80002bc0:	69a2                	ld	s3,8(sp)
    80002bc2:	6145                	addi	sp,sp,48
    80002bc4:	8082                	ret

0000000080002bc6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	ef2080e7          	jalr	-270(ra) # 80002ac4 <argraw>
    80002bda:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bdc:	4501                	li	a0,0
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	64a2                	ld	s1,8(sp)
    80002be4:	6105                	addi	sp,sp,32
    80002be6:	8082                	ret

0000000080002be8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	e426                	sd	s1,8(sp)
    80002bf0:	1000                	addi	s0,sp,32
    80002bf2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	ed0080e7          	jalr	-304(ra) # 80002ac4 <argraw>
    80002bfc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bfe:	4501                	li	a0,0
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6105                	addi	sp,sp,32
    80002c08:	8082                	ret

0000000080002c0a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c0a:	1101                	addi	sp,sp,-32
    80002c0c:	ec06                	sd	ra,24(sp)
    80002c0e:	e822                	sd	s0,16(sp)
    80002c10:	e426                	sd	s1,8(sp)
    80002c12:	e04a                	sd	s2,0(sp)
    80002c14:	1000                	addi	s0,sp,32
    80002c16:	84ae                	mv	s1,a1
    80002c18:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	eaa080e7          	jalr	-342(ra) # 80002ac4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c22:	864a                	mv	a2,s2
    80002c24:	85a6                	mv	a1,s1
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	f58080e7          	jalr	-168(ra) # 80002b7e <fetchstr>
}
    80002c2e:	60e2                	ld	ra,24(sp)
    80002c30:	6442                	ld	s0,16(sp)
    80002c32:	64a2                	ld	s1,8(sp)
    80002c34:	6902                	ld	s2,0(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret

0000000080002c3a <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	e04a                	sd	s2,0(sp)
    80002c44:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	e1e080e7          	jalr	-482(ra) # 80001a64 <myproc>
    80002c4e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c50:	05853903          	ld	s2,88(a0)
    80002c54:	0a893783          	ld	a5,168(s2)
    80002c58:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c5c:	37fd                	addiw	a5,a5,-1
    80002c5e:	4759                	li	a4,22
    80002c60:	00f76f63          	bltu	a4,a5,80002c7e <syscall+0x44>
    80002c64:	00369713          	slli	a4,a3,0x3
    80002c68:	00006797          	auipc	a5,0x6
    80002c6c:	80078793          	addi	a5,a5,-2048 # 80008468 <syscalls>
    80002c70:	97ba                	add	a5,a5,a4
    80002c72:	639c                	ld	a5,0(a5)
    80002c74:	c789                	beqz	a5,80002c7e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c76:	9782                	jalr	a5
    80002c78:	06a93823          	sd	a0,112(s2)
    80002c7c:	a839                	j	80002c9a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c7e:	15848613          	addi	a2,s1,344
    80002c82:	5c8c                	lw	a1,56(s1)
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	7ac50513          	addi	a0,a0,1964 # 80008430 <states.1712+0x170>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	9be080e7          	jalr	-1602(ra) # 8000064a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c94:	6cbc                	ld	a5,88(s1)
    80002c96:	577d                	li	a4,-1
    80002c98:	fbb8                	sd	a4,112(a5)
  }
}
    80002c9a:	60e2                	ld	ra,24(sp)
    80002c9c:	6442                	ld	s0,16(sp)
    80002c9e:	64a2                	ld	s1,8(sp)
    80002ca0:	6902                	ld	s2,0(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cae:	fec40593          	addi	a1,s0,-20
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	f12080e7          	jalr	-238(ra) # 80002bc6 <argint>
    return -1;
    80002cbc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cbe:	00054963          	bltz	a0,80002cd0 <sys_exit+0x2a>
  exit(n);
    80002cc2:	fec42503          	lw	a0,-20(s0)
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	4be080e7          	jalr	1214(ra) # 80002184 <exit>
  return 0;  // not reached
    80002cce:	4781                	li	a5,0
}
    80002cd0:	853e                	mv	a0,a5
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cda:	1141                	addi	sp,sp,-16
    80002cdc:	e406                	sd	ra,8(sp)
    80002cde:	e022                	sd	s0,0(sp)
    80002ce0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	d82080e7          	jalr	-638(ra) # 80001a64 <myproc>
}
    80002cea:	5d08                	lw	a0,56(a0)
    80002cec:	60a2                	ld	ra,8(sp)
    80002cee:	6402                	ld	s0,0(sp)
    80002cf0:	0141                	addi	sp,sp,16
    80002cf2:	8082                	ret

0000000080002cf4 <sys_fork>:

uint64
sys_fork(void)
{
    80002cf4:	1141                	addi	sp,sp,-16
    80002cf6:	e406                	sd	ra,8(sp)
    80002cf8:	e022                	sd	s0,0(sp)
    80002cfa:	0800                	addi	s0,sp,16
  return fork();
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	182080e7          	jalr	386(ra) # 80001e7e <fork>
}
    80002d04:	60a2                	ld	ra,8(sp)
    80002d06:	6402                	ld	s0,0(sp)
    80002d08:	0141                	addi	sp,sp,16
    80002d0a:	8082                	ret

0000000080002d0c <sys_wait>:

uint64
sys_wait(void)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d14:	fe840593          	addi	a1,s0,-24
    80002d18:	4501                	li	a0,0
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	ece080e7          	jalr	-306(ra) # 80002be8 <argaddr>
    80002d22:	87aa                	mv	a5,a0
    return -1;
    80002d24:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d26:	0007c863          	bltz	a5,80002d36 <sys_wait+0x2a>
  return wait(p);
    80002d2a:	fe843503          	ld	a0,-24(s0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	61a080e7          	jalr	1562(ra) # 80002348 <wait>
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d48:	fdc40593          	addi	a1,s0,-36
    80002d4c:	4501                	li	a0,0
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	e78080e7          	jalr	-392(ra) # 80002bc6 <argint>
    80002d56:	87aa                	mv	a5,a0
    return -1;
    80002d58:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d5a:	0207c063          	bltz	a5,80002d7a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	d06080e7          	jalr	-762(ra) # 80001a64 <myproc>
    80002d66:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d68:	fdc42503          	lw	a0,-36(s0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	09e080e7          	jalr	158(ra) # 80001e0a <growproc>
    80002d74:	00054863          	bltz	a0,80002d84 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d78:	8526                	mv	a0,s1
}
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6145                	addi	sp,sp,48
    80002d82:	8082                	ret
    return -1;
    80002d84:	557d                	li	a0,-1
    80002d86:	bfd5                	j	80002d7a <sys_sbrk+0x3c>

0000000080002d88 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d88:	7139                	addi	sp,sp,-64
    80002d8a:	fc06                	sd	ra,56(sp)
    80002d8c:	f822                	sd	s0,48(sp)
    80002d8e:	f426                	sd	s1,40(sp)
    80002d90:	f04a                	sd	s2,32(sp)
    80002d92:	ec4e                	sd	s3,24(sp)
    80002d94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d96:	fcc40593          	addi	a1,s0,-52
    80002d9a:	4501                	li	a0,0
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	e2a080e7          	jalr	-470(ra) # 80002bc6 <argint>
    return -1;
    80002da4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002da6:	06054963          	bltz	a0,80002e18 <sys_sleep+0x90>
  acquire(&tickslock);
    80002daa:	00015517          	auipc	a0,0x15
    80002dae:	3be50513          	addi	a0,a0,958 # 80018168 <tickslock>
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	ee4080e7          	jalr	-284(ra) # 80000c96 <acquire>
  ticks0 = ticks;
    80002dba:	00006917          	auipc	s2,0x6
    80002dbe:	26692903          	lw	s2,614(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dc2:	fcc42783          	lw	a5,-52(s0)
    80002dc6:	cf85                	beqz	a5,80002dfe <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dc8:	00015997          	auipc	s3,0x15
    80002dcc:	3a098993          	addi	s3,s3,928 # 80018168 <tickslock>
    80002dd0:	00006497          	auipc	s1,0x6
    80002dd4:	25048493          	addi	s1,s1,592 # 80009020 <ticks>
    if(myproc()->killed){
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	c8c080e7          	jalr	-884(ra) # 80001a64 <myproc>
    80002de0:	591c                	lw	a5,48(a0)
    80002de2:	e3b9                	bnez	a5,80002e28 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002de4:	85ce                	mv	a1,s3
    80002de6:	8526                	mv	a0,s1
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	4e2080e7          	jalr	1250(ra) # 800022ca <sleep>
  while(ticks - ticks0 < n){
    80002df0:	409c                	lw	a5,0(s1)
    80002df2:	412787bb          	subw	a5,a5,s2
    80002df6:	fcc42703          	lw	a4,-52(s0)
    80002dfa:	fce7efe3          	bltu	a5,a4,80002dd8 <sys_sleep+0x50>
  }

  backtrace();
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	77c080e7          	jalr	1916(ra) # 8000057a <backtrace>
  release(&tickslock);
    80002e06:	00015517          	auipc	a0,0x15
    80002e0a:	36250513          	addi	a0,a0,866 # 80018168 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	f3c080e7          	jalr	-196(ra) # 80000d4a <release>
  return 0;
    80002e16:	4781                	li	a5,0
}
    80002e18:	853e                	mv	a0,a5
    80002e1a:	70e2                	ld	ra,56(sp)
    80002e1c:	7442                	ld	s0,48(sp)
    80002e1e:	74a2                	ld	s1,40(sp)
    80002e20:	7902                	ld	s2,32(sp)
    80002e22:	69e2                	ld	s3,24(sp)
    80002e24:	6121                	addi	sp,sp,64
    80002e26:	8082                	ret
      release(&tickslock);
    80002e28:	00015517          	auipc	a0,0x15
    80002e2c:	34050513          	addi	a0,a0,832 # 80018168 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	f1a080e7          	jalr	-230(ra) # 80000d4a <release>
      return -1;
    80002e38:	57fd                	li	a5,-1
    80002e3a:	bff9                	j	80002e18 <sys_sleep+0x90>

0000000080002e3c <sys_kill>:

uint64
sys_kill(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e44:	fec40593          	addi	a1,s0,-20
    80002e48:	4501                	li	a0,0
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	d7c080e7          	jalr	-644(ra) # 80002bc6 <argint>
    80002e52:	87aa                	mv	a5,a0
    return -1;
    80002e54:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e56:	0007c863          	bltz	a5,80002e66 <sys_kill+0x2a>
  return kill(pid);
    80002e5a:	fec42503          	lw	a0,-20(s0)
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	65c080e7          	jalr	1628(ra) # 800024ba <kill>
}
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e78:	00015517          	auipc	a0,0x15
    80002e7c:	2f050513          	addi	a0,a0,752 # 80018168 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	e16080e7          	jalr	-490(ra) # 80000c96 <acquire>
  xticks = ticks;
    80002e88:	00006497          	auipc	s1,0x6
    80002e8c:	1984a483          	lw	s1,408(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e90:	00015517          	auipc	a0,0x15
    80002e94:	2d850513          	addi	a0,a0,728 # 80018168 <tickslock>
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	eb2080e7          	jalr	-334(ra) # 80000d4a <release>
  return xticks;
}
    80002ea0:	02049513          	slli	a0,s1,0x20
    80002ea4:	9101                	srli	a0,a0,0x20
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	64a2                	ld	s1,8(sp)
    80002eac:	6105                	addi	sp,sp,32
    80002eae:	8082                	ret

0000000080002eb0 <sys_sigalarm>:

uint64
sys_sigalarm(void) {
    80002eb0:	1101                	addi	sp,sp,-32
    80002eb2:	ec06                	sd	ra,24(sp)
    80002eb4:	e822                	sd	s0,16(sp)
    80002eb6:	1000                	addi	s0,sp,32
  int interval;
  uint64 handler;

  if(argint(0, &interval) < 0) {
    80002eb8:	fec40593          	addi	a1,s0,-20
    80002ebc:	4501                	li	a0,0
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	d08080e7          	jalr	-760(ra) # 80002bc6 <argint>
    return -1;
    80002ec6:	57fd                	li	a5,-1
  if(argint(0, &interval) < 0) {
    80002ec8:	02054963          	bltz	a0,80002efa <sys_sigalarm+0x4a>
  }

  if(argaddr(1, &handler) < 0) {
    80002ecc:	fe040593          	addi	a1,s0,-32
    80002ed0:	4505                	li	a0,1
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	d16080e7          	jalr	-746(ra) # 80002be8 <argaddr>
    return -1;
    80002eda:	57fd                	li	a5,-1
  if(argaddr(1, &handler) < 0) {
    80002edc:	00054f63          	bltz	a0,80002efa <sys_sigalarm+0x4a>
  }

  struct proc* p = myproc();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	b84080e7          	jalr	-1148(ra) # 80001a64 <myproc>
  p->interval = interval;
    80002ee8:	fec42783          	lw	a5,-20(s0)
    80002eec:	16f53423          	sd	a5,360(a0)
  p->handler = handler;
    80002ef0:	fe043783          	ld	a5,-32(s0)
    80002ef4:	16f53823          	sd	a5,368(a0)

  return 0;
    80002ef8:	4781                	li	a5,0
}
    80002efa:	853e                	mv	a0,a5
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_sigreturn>:

uint64 
sys_sigreturn(void) {
    80002f04:	1101                	addi	sp,sp,-32
    80002f06:	ec06                	sd	ra,24(sp)
    80002f08:	e822                	sd	s0,16(sp)
    80002f0a:	e426                	sd	s1,8(sp)
    80002f0c:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	b56080e7          	jalr	-1194(ra) # 80001a64 <myproc>
    80002f16:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_trapframe, sizeof(struct trapframe));
    80002f18:	12000613          	li	a2,288
    80002f1c:	18853583          	ld	a1,392(a0)
    80002f20:	6d28                	ld	a0,88(a0)
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	ed0080e7          	jalr	-304(ra) # 80000df2 <memmove>
  p->ticks = 0;
    80002f2a:	1604bc23          	sd	zero,376(s1)
  p->is_alarm = 0;
    80002f2e:	1804b023          	sd	zero,384(s1)
  return 0;
    80002f32:	4501                	li	a0,0
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	64a2                	ld	s1,8(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f3e:	7179                	addi	sp,sp,-48
    80002f40:	f406                	sd	ra,40(sp)
    80002f42:	f022                	sd	s0,32(sp)
    80002f44:	ec26                	sd	s1,24(sp)
    80002f46:	e84a                	sd	s2,16(sp)
    80002f48:	e44e                	sd	s3,8(sp)
    80002f4a:	e052                	sd	s4,0(sp)
    80002f4c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f4e:	00005597          	auipc	a1,0x5
    80002f52:	5da58593          	addi	a1,a1,1498 # 80008528 <syscalls+0xc0>
    80002f56:	00015517          	auipc	a0,0x15
    80002f5a:	22a50513          	addi	a0,a0,554 # 80018180 <bcache>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	ca8080e7          	jalr	-856(ra) # 80000c06 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f66:	0001d797          	auipc	a5,0x1d
    80002f6a:	21a78793          	addi	a5,a5,538 # 80020180 <bcache+0x8000>
    80002f6e:	0001d717          	auipc	a4,0x1d
    80002f72:	47a70713          	addi	a4,a4,1146 # 800203e8 <bcache+0x8268>
    80002f76:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f7a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7e:	00015497          	auipc	s1,0x15
    80002f82:	21a48493          	addi	s1,s1,538 # 80018198 <bcache+0x18>
    b->next = bcache.head.next;
    80002f86:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f88:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f8a:	00005a17          	auipc	s4,0x5
    80002f8e:	5a6a0a13          	addi	s4,s4,1446 # 80008530 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f92:	2b893783          	ld	a5,696(s2)
    80002f96:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f98:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f9c:	85d2                	mv	a1,s4
    80002f9e:	01048513          	addi	a0,s1,16
    80002fa2:	00001097          	auipc	ra,0x1
    80002fa6:	4ac080e7          	jalr	1196(ra) # 8000444e <initsleeplock>
    bcache.head.next->prev = b;
    80002faa:	2b893783          	ld	a5,696(s2)
    80002fae:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fb0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb4:	45848493          	addi	s1,s1,1112
    80002fb8:	fd349de3          	bne	s1,s3,80002f92 <binit+0x54>
  }
}
    80002fbc:	70a2                	ld	ra,40(sp)
    80002fbe:	7402                	ld	s0,32(sp)
    80002fc0:	64e2                	ld	s1,24(sp)
    80002fc2:	6942                	ld	s2,16(sp)
    80002fc4:	69a2                	ld	s3,8(sp)
    80002fc6:	6a02                	ld	s4,0(sp)
    80002fc8:	6145                	addi	sp,sp,48
    80002fca:	8082                	ret

0000000080002fcc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fcc:	7179                	addi	sp,sp,-48
    80002fce:	f406                	sd	ra,40(sp)
    80002fd0:	f022                	sd	s0,32(sp)
    80002fd2:	ec26                	sd	s1,24(sp)
    80002fd4:	e84a                	sd	s2,16(sp)
    80002fd6:	e44e                	sd	s3,8(sp)
    80002fd8:	1800                	addi	s0,sp,48
    80002fda:	89aa                	mv	s3,a0
    80002fdc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fde:	00015517          	auipc	a0,0x15
    80002fe2:	1a250513          	addi	a0,a0,418 # 80018180 <bcache>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	cb0080e7          	jalr	-848(ra) # 80000c96 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fee:	0001d497          	auipc	s1,0x1d
    80002ff2:	44a4b483          	ld	s1,1098(s1) # 80020438 <bcache+0x82b8>
    80002ff6:	0001d797          	auipc	a5,0x1d
    80002ffa:	3f278793          	addi	a5,a5,1010 # 800203e8 <bcache+0x8268>
    80002ffe:	02f48f63          	beq	s1,a5,8000303c <bread+0x70>
    80003002:	873e                	mv	a4,a5
    80003004:	a021                	j	8000300c <bread+0x40>
    80003006:	68a4                	ld	s1,80(s1)
    80003008:	02e48a63          	beq	s1,a4,8000303c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000300c:	449c                	lw	a5,8(s1)
    8000300e:	ff379ce3          	bne	a5,s3,80003006 <bread+0x3a>
    80003012:	44dc                	lw	a5,12(s1)
    80003014:	ff2799e3          	bne	a5,s2,80003006 <bread+0x3a>
      b->refcnt++;
    80003018:	40bc                	lw	a5,64(s1)
    8000301a:	2785                	addiw	a5,a5,1
    8000301c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301e:	00015517          	auipc	a0,0x15
    80003022:	16250513          	addi	a0,a0,354 # 80018180 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	d24080e7          	jalr	-732(ra) # 80000d4a <release>
      acquiresleep(&b->lock);
    8000302e:	01048513          	addi	a0,s1,16
    80003032:	00001097          	auipc	ra,0x1
    80003036:	456080e7          	jalr	1110(ra) # 80004488 <acquiresleep>
      return b;
    8000303a:	a8b9                	j	80003098 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303c:	0001d497          	auipc	s1,0x1d
    80003040:	3f44b483          	ld	s1,1012(s1) # 80020430 <bcache+0x82b0>
    80003044:	0001d797          	auipc	a5,0x1d
    80003048:	3a478793          	addi	a5,a5,932 # 800203e8 <bcache+0x8268>
    8000304c:	00f48863          	beq	s1,a5,8000305c <bread+0x90>
    80003050:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003052:	40bc                	lw	a5,64(s1)
    80003054:	cf81                	beqz	a5,8000306c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003056:	64a4                	ld	s1,72(s1)
    80003058:	fee49de3          	bne	s1,a4,80003052 <bread+0x86>
  panic("bget: no buffers");
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	4dc50513          	addi	a0,a0,1244 # 80008538 <syscalls+0xd0>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	594080e7          	jalr	1428(ra) # 800005f8 <panic>
      b->dev = dev;
    8000306c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003070:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003074:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003078:	4785                	li	a5,1
    8000307a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307c:	00015517          	auipc	a0,0x15
    80003080:	10450513          	addi	a0,a0,260 # 80018180 <bcache>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	cc6080e7          	jalr	-826(ra) # 80000d4a <release>
      acquiresleep(&b->lock);
    8000308c:	01048513          	addi	a0,s1,16
    80003090:	00001097          	auipc	ra,0x1
    80003094:	3f8080e7          	jalr	1016(ra) # 80004488 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003098:	409c                	lw	a5,0(s1)
    8000309a:	cb89                	beqz	a5,800030ac <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000309c:	8526                	mv	a0,s1
    8000309e:	70a2                	ld	ra,40(sp)
    800030a0:	7402                	ld	s0,32(sp)
    800030a2:	64e2                	ld	s1,24(sp)
    800030a4:	6942                	ld	s2,16(sp)
    800030a6:	69a2                	ld	s3,8(sp)
    800030a8:	6145                	addi	sp,sp,48
    800030aa:	8082                	ret
    virtio_disk_rw(b, 0);
    800030ac:	4581                	li	a1,0
    800030ae:	8526                	mv	a0,s1
    800030b0:	00003097          	auipc	ra,0x3
    800030b4:	f2c080e7          	jalr	-212(ra) # 80005fdc <virtio_disk_rw>
    b->valid = 1;
    800030b8:	4785                	li	a5,1
    800030ba:	c09c                	sw	a5,0(s1)
  return b;
    800030bc:	b7c5                	j	8000309c <bread+0xd0>

00000000800030be <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030be:	1101                	addi	sp,sp,-32
    800030c0:	ec06                	sd	ra,24(sp)
    800030c2:	e822                	sd	s0,16(sp)
    800030c4:	e426                	sd	s1,8(sp)
    800030c6:	1000                	addi	s0,sp,32
    800030c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ca:	0541                	addi	a0,a0,16
    800030cc:	00001097          	auipc	ra,0x1
    800030d0:	456080e7          	jalr	1110(ra) # 80004522 <holdingsleep>
    800030d4:	cd01                	beqz	a0,800030ec <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030d6:	4585                	li	a1,1
    800030d8:	8526                	mv	a0,s1
    800030da:	00003097          	auipc	ra,0x3
    800030de:	f02080e7          	jalr	-254(ra) # 80005fdc <virtio_disk_rw>
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret
    panic("bwrite");
    800030ec:	00005517          	auipc	a0,0x5
    800030f0:	46450513          	addi	a0,a0,1124 # 80008550 <syscalls+0xe8>
    800030f4:	ffffd097          	auipc	ra,0xffffd
    800030f8:	504080e7          	jalr	1284(ra) # 800005f8 <panic>

00000000800030fc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030fc:	1101                	addi	sp,sp,-32
    800030fe:	ec06                	sd	ra,24(sp)
    80003100:	e822                	sd	s0,16(sp)
    80003102:	e426                	sd	s1,8(sp)
    80003104:	e04a                	sd	s2,0(sp)
    80003106:	1000                	addi	s0,sp,32
    80003108:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000310a:	01050913          	addi	s2,a0,16
    8000310e:	854a                	mv	a0,s2
    80003110:	00001097          	auipc	ra,0x1
    80003114:	412080e7          	jalr	1042(ra) # 80004522 <holdingsleep>
    80003118:	c92d                	beqz	a0,8000318a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000311a:	854a                	mv	a0,s2
    8000311c:	00001097          	auipc	ra,0x1
    80003120:	3c2080e7          	jalr	962(ra) # 800044de <releasesleep>

  acquire(&bcache.lock);
    80003124:	00015517          	auipc	a0,0x15
    80003128:	05c50513          	addi	a0,a0,92 # 80018180 <bcache>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b6a080e7          	jalr	-1174(ra) # 80000c96 <acquire>
  b->refcnt--;
    80003134:	40bc                	lw	a5,64(s1)
    80003136:	37fd                	addiw	a5,a5,-1
    80003138:	0007871b          	sext.w	a4,a5
    8000313c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000313e:	eb05                	bnez	a4,8000316e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003140:	68bc                	ld	a5,80(s1)
    80003142:	64b8                	ld	a4,72(s1)
    80003144:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003146:	64bc                	ld	a5,72(s1)
    80003148:	68b8                	ld	a4,80(s1)
    8000314a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000314c:	0001d797          	auipc	a5,0x1d
    80003150:	03478793          	addi	a5,a5,52 # 80020180 <bcache+0x8000>
    80003154:	2b87b703          	ld	a4,696(a5)
    80003158:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000315a:	0001d717          	auipc	a4,0x1d
    8000315e:	28e70713          	addi	a4,a4,654 # 800203e8 <bcache+0x8268>
    80003162:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003164:	2b87b703          	ld	a4,696(a5)
    80003168:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000316a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000316e:	00015517          	auipc	a0,0x15
    80003172:	01250513          	addi	a0,a0,18 # 80018180 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	bd4080e7          	jalr	-1068(ra) # 80000d4a <release>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	64a2                	ld	s1,8(sp)
    80003184:	6902                	ld	s2,0(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret
    panic("brelse");
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	3ce50513          	addi	a0,a0,974 # 80008558 <syscalls+0xf0>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	466080e7          	jalr	1126(ra) # 800005f8 <panic>

000000008000319a <bpin>:

void
bpin(struct buf *b) {
    8000319a:	1101                	addi	sp,sp,-32
    8000319c:	ec06                	sd	ra,24(sp)
    8000319e:	e822                	sd	s0,16(sp)
    800031a0:	e426                	sd	s1,8(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a6:	00015517          	auipc	a0,0x15
    800031aa:	fda50513          	addi	a0,a0,-38 # 80018180 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	ae8080e7          	jalr	-1304(ra) # 80000c96 <acquire>
  b->refcnt++;
    800031b6:	40bc                	lw	a5,64(s1)
    800031b8:	2785                	addiw	a5,a5,1
    800031ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031bc:	00015517          	auipc	a0,0x15
    800031c0:	fc450513          	addi	a0,a0,-60 # 80018180 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	b86080e7          	jalr	-1146(ra) # 80000d4a <release>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	64a2                	ld	s1,8(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <bunpin>:

void
bunpin(struct buf *b) {
    800031d6:	1101                	addi	sp,sp,-32
    800031d8:	ec06                	sd	ra,24(sp)
    800031da:	e822                	sd	s0,16(sp)
    800031dc:	e426                	sd	s1,8(sp)
    800031de:	1000                	addi	s0,sp,32
    800031e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031e2:	00015517          	auipc	a0,0x15
    800031e6:	f9e50513          	addi	a0,a0,-98 # 80018180 <bcache>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	aac080e7          	jalr	-1364(ra) # 80000c96 <acquire>
  b->refcnt--;
    800031f2:	40bc                	lw	a5,64(s1)
    800031f4:	37fd                	addiw	a5,a5,-1
    800031f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f8:	00015517          	auipc	a0,0x15
    800031fc:	f8850513          	addi	a0,a0,-120 # 80018180 <bcache>
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	b4a080e7          	jalr	-1206(ra) # 80000d4a <release>
}
    80003208:	60e2                	ld	ra,24(sp)
    8000320a:	6442                	ld	s0,16(sp)
    8000320c:	64a2                	ld	s1,8(sp)
    8000320e:	6105                	addi	sp,sp,32
    80003210:	8082                	ret

0000000080003212 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	e426                	sd	s1,8(sp)
    8000321a:	e04a                	sd	s2,0(sp)
    8000321c:	1000                	addi	s0,sp,32
    8000321e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003220:	00d5d59b          	srliw	a1,a1,0xd
    80003224:	0001d797          	auipc	a5,0x1d
    80003228:	6387a783          	lw	a5,1592(a5) # 8002085c <sb+0x1c>
    8000322c:	9dbd                	addw	a1,a1,a5
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	d9e080e7          	jalr	-610(ra) # 80002fcc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003236:	0074f713          	andi	a4,s1,7
    8000323a:	4785                	li	a5,1
    8000323c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003240:	14ce                	slli	s1,s1,0x33
    80003242:	90d9                	srli	s1,s1,0x36
    80003244:	00950733          	add	a4,a0,s1
    80003248:	05874703          	lbu	a4,88(a4)
    8000324c:	00e7f6b3          	and	a3,a5,a4
    80003250:	c69d                	beqz	a3,8000327e <bfree+0x6c>
    80003252:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003254:	94aa                	add	s1,s1,a0
    80003256:	fff7c793          	not	a5,a5
    8000325a:	8ff9                	and	a5,a5,a4
    8000325c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003260:	00001097          	auipc	ra,0x1
    80003264:	100080e7          	jalr	256(ra) # 80004360 <log_write>
  brelse(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e92080e7          	jalr	-366(ra) # 800030fc <brelse>
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6902                	ld	s2,0(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret
    panic("freeing free block");
    8000327e:	00005517          	auipc	a0,0x5
    80003282:	2e250513          	addi	a0,a0,738 # 80008560 <syscalls+0xf8>
    80003286:	ffffd097          	auipc	ra,0xffffd
    8000328a:	372080e7          	jalr	882(ra) # 800005f8 <panic>

000000008000328e <balloc>:
{
    8000328e:	711d                	addi	sp,sp,-96
    80003290:	ec86                	sd	ra,88(sp)
    80003292:	e8a2                	sd	s0,80(sp)
    80003294:	e4a6                	sd	s1,72(sp)
    80003296:	e0ca                	sd	s2,64(sp)
    80003298:	fc4e                	sd	s3,56(sp)
    8000329a:	f852                	sd	s4,48(sp)
    8000329c:	f456                	sd	s5,40(sp)
    8000329e:	f05a                	sd	s6,32(sp)
    800032a0:	ec5e                	sd	s7,24(sp)
    800032a2:	e862                	sd	s8,16(sp)
    800032a4:	e466                	sd	s9,8(sp)
    800032a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032a8:	0001d797          	auipc	a5,0x1d
    800032ac:	59c7a783          	lw	a5,1436(a5) # 80020844 <sb+0x4>
    800032b0:	cbd1                	beqz	a5,80003344 <balloc+0xb6>
    800032b2:	8baa                	mv	s7,a0
    800032b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032b6:	0001db17          	auipc	s6,0x1d
    800032ba:	58ab0b13          	addi	s6,s6,1418 # 80020840 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032c4:	6c89                	lui	s9,0x2
    800032c6:	a831                	j	800032e2 <balloc+0x54>
    brelse(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	e32080e7          	jalr	-462(ra) # 800030fc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032d2:	015c87bb          	addw	a5,s9,s5
    800032d6:	00078a9b          	sext.w	s5,a5
    800032da:	004b2703          	lw	a4,4(s6)
    800032de:	06eaf363          	bgeu	s5,a4,80003344 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032e2:	41fad79b          	sraiw	a5,s5,0x1f
    800032e6:	0137d79b          	srliw	a5,a5,0x13
    800032ea:	015787bb          	addw	a5,a5,s5
    800032ee:	40d7d79b          	sraiw	a5,a5,0xd
    800032f2:	01cb2583          	lw	a1,28(s6)
    800032f6:	9dbd                	addw	a1,a1,a5
    800032f8:	855e                	mv	a0,s7
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	cd2080e7          	jalr	-814(ra) # 80002fcc <bread>
    80003302:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003304:	004b2503          	lw	a0,4(s6)
    80003308:	000a849b          	sext.w	s1,s5
    8000330c:	8662                	mv	a2,s8
    8000330e:	faa4fde3          	bgeu	s1,a0,800032c8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003312:	41f6579b          	sraiw	a5,a2,0x1f
    80003316:	01d7d69b          	srliw	a3,a5,0x1d
    8000331a:	00c6873b          	addw	a4,a3,a2
    8000331e:	00777793          	andi	a5,a4,7
    80003322:	9f95                	subw	a5,a5,a3
    80003324:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003328:	4037571b          	sraiw	a4,a4,0x3
    8000332c:	00e906b3          	add	a3,s2,a4
    80003330:	0586c683          	lbu	a3,88(a3)
    80003334:	00d7f5b3          	and	a1,a5,a3
    80003338:	cd91                	beqz	a1,80003354 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333a:	2605                	addiw	a2,a2,1
    8000333c:	2485                	addiw	s1,s1,1
    8000333e:	fd4618e3          	bne	a2,s4,8000330e <balloc+0x80>
    80003342:	b759                	j	800032c8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003344:	00005517          	auipc	a0,0x5
    80003348:	23450513          	addi	a0,a0,564 # 80008578 <syscalls+0x110>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	2ac080e7          	jalr	684(ra) # 800005f8 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003354:	974a                	add	a4,a4,s2
    80003356:	8fd5                	or	a5,a5,a3
    80003358:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000335c:	854a                	mv	a0,s2
    8000335e:	00001097          	auipc	ra,0x1
    80003362:	002080e7          	jalr	2(ra) # 80004360 <log_write>
        brelse(bp);
    80003366:	854a                	mv	a0,s2
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	d94080e7          	jalr	-620(ra) # 800030fc <brelse>
  bp = bread(dev, bno);
    80003370:	85a6                	mv	a1,s1
    80003372:	855e                	mv	a0,s7
    80003374:	00000097          	auipc	ra,0x0
    80003378:	c58080e7          	jalr	-936(ra) # 80002fcc <bread>
    8000337c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000337e:	40000613          	li	a2,1024
    80003382:	4581                	li	a1,0
    80003384:	05850513          	addi	a0,a0,88
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	a0a080e7          	jalr	-1526(ra) # 80000d92 <memset>
  log_write(bp);
    80003390:	854a                	mv	a0,s2
    80003392:	00001097          	auipc	ra,0x1
    80003396:	fce080e7          	jalr	-50(ra) # 80004360 <log_write>
  brelse(bp);
    8000339a:	854a                	mv	a0,s2
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	d60080e7          	jalr	-672(ra) # 800030fc <brelse>
}
    800033a4:	8526                	mv	a0,s1
    800033a6:	60e6                	ld	ra,88(sp)
    800033a8:	6446                	ld	s0,80(sp)
    800033aa:	64a6                	ld	s1,72(sp)
    800033ac:	6906                	ld	s2,64(sp)
    800033ae:	79e2                	ld	s3,56(sp)
    800033b0:	7a42                	ld	s4,48(sp)
    800033b2:	7aa2                	ld	s5,40(sp)
    800033b4:	7b02                	ld	s6,32(sp)
    800033b6:	6be2                	ld	s7,24(sp)
    800033b8:	6c42                	ld	s8,16(sp)
    800033ba:	6ca2                	ld	s9,8(sp)
    800033bc:	6125                	addi	sp,sp,96
    800033be:	8082                	ret

00000000800033c0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033c0:	7179                	addi	sp,sp,-48
    800033c2:	f406                	sd	ra,40(sp)
    800033c4:	f022                	sd	s0,32(sp)
    800033c6:	ec26                	sd	s1,24(sp)
    800033c8:	e84a                	sd	s2,16(sp)
    800033ca:	e44e                	sd	s3,8(sp)
    800033cc:	e052                	sd	s4,0(sp)
    800033ce:	1800                	addi	s0,sp,48
    800033d0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033d2:	47ad                	li	a5,11
    800033d4:	04b7fe63          	bgeu	a5,a1,80003430 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033d8:	ff45849b          	addiw	s1,a1,-12
    800033dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033e0:	0ff00793          	li	a5,255
    800033e4:	0ae7e363          	bltu	a5,a4,8000348a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033e8:	08052583          	lw	a1,128(a0)
    800033ec:	c5ad                	beqz	a1,80003456 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033ee:	00092503          	lw	a0,0(s2)
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	bda080e7          	jalr	-1062(ra) # 80002fcc <bread>
    800033fa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033fc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003400:	02049593          	slli	a1,s1,0x20
    80003404:	9181                	srli	a1,a1,0x20
    80003406:	058a                	slli	a1,a1,0x2
    80003408:	00b784b3          	add	s1,a5,a1
    8000340c:	0004a983          	lw	s3,0(s1)
    80003410:	04098d63          	beqz	s3,8000346a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003414:	8552                	mv	a0,s4
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	ce6080e7          	jalr	-794(ra) # 800030fc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000341e:	854e                	mv	a0,s3
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6942                	ld	s2,16(sp)
    80003428:	69a2                	ld	s3,8(sp)
    8000342a:	6a02                	ld	s4,0(sp)
    8000342c:	6145                	addi	sp,sp,48
    8000342e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003430:	02059493          	slli	s1,a1,0x20
    80003434:	9081                	srli	s1,s1,0x20
    80003436:	048a                	slli	s1,s1,0x2
    80003438:	94aa                	add	s1,s1,a0
    8000343a:	0504a983          	lw	s3,80(s1)
    8000343e:	fe0990e3          	bnez	s3,8000341e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003442:	4108                	lw	a0,0(a0)
    80003444:	00000097          	auipc	ra,0x0
    80003448:	e4a080e7          	jalr	-438(ra) # 8000328e <balloc>
    8000344c:	0005099b          	sext.w	s3,a0
    80003450:	0534a823          	sw	s3,80(s1)
    80003454:	b7e9                	j	8000341e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003456:	4108                	lw	a0,0(a0)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e36080e7          	jalr	-458(ra) # 8000328e <balloc>
    80003460:	0005059b          	sext.w	a1,a0
    80003464:	08b92023          	sw	a1,128(s2)
    80003468:	b759                	j	800033ee <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000346a:	00092503          	lw	a0,0(s2)
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	e20080e7          	jalr	-480(ra) # 8000328e <balloc>
    80003476:	0005099b          	sext.w	s3,a0
    8000347a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000347e:	8552                	mv	a0,s4
    80003480:	00001097          	auipc	ra,0x1
    80003484:	ee0080e7          	jalr	-288(ra) # 80004360 <log_write>
    80003488:	b771                	j	80003414 <bmap+0x54>
  panic("bmap: out of range");
    8000348a:	00005517          	auipc	a0,0x5
    8000348e:	10650513          	addi	a0,a0,262 # 80008590 <syscalls+0x128>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	166080e7          	jalr	358(ra) # 800005f8 <panic>

000000008000349a <iget>:
{
    8000349a:	7179                	addi	sp,sp,-48
    8000349c:	f406                	sd	ra,40(sp)
    8000349e:	f022                	sd	s0,32(sp)
    800034a0:	ec26                	sd	s1,24(sp)
    800034a2:	e84a                	sd	s2,16(sp)
    800034a4:	e44e                	sd	s3,8(sp)
    800034a6:	e052                	sd	s4,0(sp)
    800034a8:	1800                	addi	s0,sp,48
    800034aa:	89aa                	mv	s3,a0
    800034ac:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034ae:	0001d517          	auipc	a0,0x1d
    800034b2:	3b250513          	addi	a0,a0,946 # 80020860 <icache>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	7e0080e7          	jalr	2016(ra) # 80000c96 <acquire>
  empty = 0;
    800034be:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034c0:	0001d497          	auipc	s1,0x1d
    800034c4:	3b848493          	addi	s1,s1,952 # 80020878 <icache+0x18>
    800034c8:	0001f697          	auipc	a3,0x1f
    800034cc:	e4068693          	addi	a3,a3,-448 # 80022308 <log>
    800034d0:	a039                	j	800034de <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d2:	02090b63          	beqz	s2,80003508 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034d6:	08848493          	addi	s1,s1,136
    800034da:	02d48a63          	beq	s1,a3,8000350e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034de:	449c                	lw	a5,8(s1)
    800034e0:	fef059e3          	blez	a5,800034d2 <iget+0x38>
    800034e4:	4098                	lw	a4,0(s1)
    800034e6:	ff3716e3          	bne	a4,s3,800034d2 <iget+0x38>
    800034ea:	40d8                	lw	a4,4(s1)
    800034ec:	ff4713e3          	bne	a4,s4,800034d2 <iget+0x38>
      ip->ref++;
    800034f0:	2785                	addiw	a5,a5,1
    800034f2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034f4:	0001d517          	auipc	a0,0x1d
    800034f8:	36c50513          	addi	a0,a0,876 # 80020860 <icache>
    800034fc:	ffffe097          	auipc	ra,0xffffe
    80003500:	84e080e7          	jalr	-1970(ra) # 80000d4a <release>
      return ip;
    80003504:	8926                	mv	s2,s1
    80003506:	a03d                	j	80003534 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003508:	f7f9                	bnez	a5,800034d6 <iget+0x3c>
    8000350a:	8926                	mv	s2,s1
    8000350c:	b7e9                	j	800034d6 <iget+0x3c>
  if(empty == 0)
    8000350e:	02090c63          	beqz	s2,80003546 <iget+0xac>
  ip->dev = dev;
    80003512:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003516:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000351a:	4785                	li	a5,1
    8000351c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003520:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003524:	0001d517          	auipc	a0,0x1d
    80003528:	33c50513          	addi	a0,a0,828 # 80020860 <icache>
    8000352c:	ffffe097          	auipc	ra,0xffffe
    80003530:	81e080e7          	jalr	-2018(ra) # 80000d4a <release>
}
    80003534:	854a                	mv	a0,s2
    80003536:	70a2                	ld	ra,40(sp)
    80003538:	7402                	ld	s0,32(sp)
    8000353a:	64e2                	ld	s1,24(sp)
    8000353c:	6942                	ld	s2,16(sp)
    8000353e:	69a2                	ld	s3,8(sp)
    80003540:	6a02                	ld	s4,0(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
    panic("iget: no inodes");
    80003546:	00005517          	auipc	a0,0x5
    8000354a:	06250513          	addi	a0,a0,98 # 800085a8 <syscalls+0x140>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	0aa080e7          	jalr	170(ra) # 800005f8 <panic>

0000000080003556 <fsinit>:
fsinit(int dev) {
    80003556:	7179                	addi	sp,sp,-48
    80003558:	f406                	sd	ra,40(sp)
    8000355a:	f022                	sd	s0,32(sp)
    8000355c:	ec26                	sd	s1,24(sp)
    8000355e:	e84a                	sd	s2,16(sp)
    80003560:	e44e                	sd	s3,8(sp)
    80003562:	1800                	addi	s0,sp,48
    80003564:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003566:	4585                	li	a1,1
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	a64080e7          	jalr	-1436(ra) # 80002fcc <bread>
    80003570:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003572:	0001d997          	auipc	s3,0x1d
    80003576:	2ce98993          	addi	s3,s3,718 # 80020840 <sb>
    8000357a:	02000613          	li	a2,32
    8000357e:	05850593          	addi	a1,a0,88
    80003582:	854e                	mv	a0,s3
    80003584:	ffffe097          	auipc	ra,0xffffe
    80003588:	86e080e7          	jalr	-1938(ra) # 80000df2 <memmove>
  brelse(bp);
    8000358c:	8526                	mv	a0,s1
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	b6e080e7          	jalr	-1170(ra) # 800030fc <brelse>
  if(sb.magic != FSMAGIC)
    80003596:	0009a703          	lw	a4,0(s3)
    8000359a:	102037b7          	lui	a5,0x10203
    8000359e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035a2:	02f71263          	bne	a4,a5,800035c6 <fsinit+0x70>
  initlog(dev, &sb);
    800035a6:	0001d597          	auipc	a1,0x1d
    800035aa:	29a58593          	addi	a1,a1,666 # 80020840 <sb>
    800035ae:	854a                	mv	a0,s2
    800035b0:	00001097          	auipc	ra,0x1
    800035b4:	b38080e7          	jalr	-1224(ra) # 800040e8 <initlog>
}
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6145                	addi	sp,sp,48
    800035c4:	8082                	ret
    panic("invalid file system");
    800035c6:	00005517          	auipc	a0,0x5
    800035ca:	ff250513          	addi	a0,a0,-14 # 800085b8 <syscalls+0x150>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	02a080e7          	jalr	42(ra) # 800005f8 <panic>

00000000800035d6 <iinit>:
{
    800035d6:	7179                	addi	sp,sp,-48
    800035d8:	f406                	sd	ra,40(sp)
    800035da:	f022                	sd	s0,32(sp)
    800035dc:	ec26                	sd	s1,24(sp)
    800035de:	e84a                	sd	s2,16(sp)
    800035e0:	e44e                	sd	s3,8(sp)
    800035e2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035e4:	00005597          	auipc	a1,0x5
    800035e8:	fec58593          	addi	a1,a1,-20 # 800085d0 <syscalls+0x168>
    800035ec:	0001d517          	auipc	a0,0x1d
    800035f0:	27450513          	addi	a0,a0,628 # 80020860 <icache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	612080e7          	jalr	1554(ra) # 80000c06 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035fc:	0001d497          	auipc	s1,0x1d
    80003600:	28c48493          	addi	s1,s1,652 # 80020888 <icache+0x28>
    80003604:	0001f997          	auipc	s3,0x1f
    80003608:	d1498993          	addi	s3,s3,-748 # 80022318 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000360c:	00005917          	auipc	s2,0x5
    80003610:	fcc90913          	addi	s2,s2,-52 # 800085d8 <syscalls+0x170>
    80003614:	85ca                	mv	a1,s2
    80003616:	8526                	mv	a0,s1
    80003618:	00001097          	auipc	ra,0x1
    8000361c:	e36080e7          	jalr	-458(ra) # 8000444e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003620:	08848493          	addi	s1,s1,136
    80003624:	ff3498e3          	bne	s1,s3,80003614 <iinit+0x3e>
}
    80003628:	70a2                	ld	ra,40(sp)
    8000362a:	7402                	ld	s0,32(sp)
    8000362c:	64e2                	ld	s1,24(sp)
    8000362e:	6942                	ld	s2,16(sp)
    80003630:	69a2                	ld	s3,8(sp)
    80003632:	6145                	addi	sp,sp,48
    80003634:	8082                	ret

0000000080003636 <ialloc>:
{
    80003636:	715d                	addi	sp,sp,-80
    80003638:	e486                	sd	ra,72(sp)
    8000363a:	e0a2                	sd	s0,64(sp)
    8000363c:	fc26                	sd	s1,56(sp)
    8000363e:	f84a                	sd	s2,48(sp)
    80003640:	f44e                	sd	s3,40(sp)
    80003642:	f052                	sd	s4,32(sp)
    80003644:	ec56                	sd	s5,24(sp)
    80003646:	e85a                	sd	s6,16(sp)
    80003648:	e45e                	sd	s7,8(sp)
    8000364a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364c:	0001d717          	auipc	a4,0x1d
    80003650:	20072703          	lw	a4,512(a4) # 8002084c <sb+0xc>
    80003654:	4785                	li	a5,1
    80003656:	04e7fa63          	bgeu	a5,a4,800036aa <ialloc+0x74>
    8000365a:	8aaa                	mv	s5,a0
    8000365c:	8bae                	mv	s7,a1
    8000365e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003660:	0001da17          	auipc	s4,0x1d
    80003664:	1e0a0a13          	addi	s4,s4,480 # 80020840 <sb>
    80003668:	00048b1b          	sext.w	s6,s1
    8000366c:	0044d593          	srli	a1,s1,0x4
    80003670:	018a2783          	lw	a5,24(s4)
    80003674:	9dbd                	addw	a1,a1,a5
    80003676:	8556                	mv	a0,s5
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	954080e7          	jalr	-1708(ra) # 80002fcc <bread>
    80003680:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003682:	05850993          	addi	s3,a0,88
    80003686:	00f4f793          	andi	a5,s1,15
    8000368a:	079a                	slli	a5,a5,0x6
    8000368c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000368e:	00099783          	lh	a5,0(s3)
    80003692:	c785                	beqz	a5,800036ba <ialloc+0x84>
    brelse(bp);
    80003694:	00000097          	auipc	ra,0x0
    80003698:	a68080e7          	jalr	-1432(ra) # 800030fc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000369c:	0485                	addi	s1,s1,1
    8000369e:	00ca2703          	lw	a4,12(s4)
    800036a2:	0004879b          	sext.w	a5,s1
    800036a6:	fce7e1e3          	bltu	a5,a4,80003668 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036aa:	00005517          	auipc	a0,0x5
    800036ae:	f3650513          	addi	a0,a0,-202 # 800085e0 <syscalls+0x178>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	f46080e7          	jalr	-186(ra) # 800005f8 <panic>
      memset(dip, 0, sizeof(*dip));
    800036ba:	04000613          	li	a2,64
    800036be:	4581                	li	a1,0
    800036c0:	854e                	mv	a0,s3
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	6d0080e7          	jalr	1744(ra) # 80000d92 <memset>
      dip->type = type;
    800036ca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ce:	854a                	mv	a0,s2
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	c90080e7          	jalr	-880(ra) # 80004360 <log_write>
      brelse(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00000097          	auipc	ra,0x0
    800036de:	a22080e7          	jalr	-1502(ra) # 800030fc <brelse>
      return iget(dev, inum);
    800036e2:	85da                	mv	a1,s6
    800036e4:	8556                	mv	a0,s5
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	db4080e7          	jalr	-588(ra) # 8000349a <iget>
}
    800036ee:	60a6                	ld	ra,72(sp)
    800036f0:	6406                	ld	s0,64(sp)
    800036f2:	74e2                	ld	s1,56(sp)
    800036f4:	7942                	ld	s2,48(sp)
    800036f6:	79a2                	ld	s3,40(sp)
    800036f8:	7a02                	ld	s4,32(sp)
    800036fa:	6ae2                	ld	s5,24(sp)
    800036fc:	6b42                	ld	s6,16(sp)
    800036fe:	6ba2                	ld	s7,8(sp)
    80003700:	6161                	addi	sp,sp,80
    80003702:	8082                	ret

0000000080003704 <iupdate>:
{
    80003704:	1101                	addi	sp,sp,-32
    80003706:	ec06                	sd	ra,24(sp)
    80003708:	e822                	sd	s0,16(sp)
    8000370a:	e426                	sd	s1,8(sp)
    8000370c:	e04a                	sd	s2,0(sp)
    8000370e:	1000                	addi	s0,sp,32
    80003710:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003712:	415c                	lw	a5,4(a0)
    80003714:	0047d79b          	srliw	a5,a5,0x4
    80003718:	0001d597          	auipc	a1,0x1d
    8000371c:	1405a583          	lw	a1,320(a1) # 80020858 <sb+0x18>
    80003720:	9dbd                	addw	a1,a1,a5
    80003722:	4108                	lw	a0,0(a0)
    80003724:	00000097          	auipc	ra,0x0
    80003728:	8a8080e7          	jalr	-1880(ra) # 80002fcc <bread>
    8000372c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000372e:	05850793          	addi	a5,a0,88
    80003732:	40c8                	lw	a0,4(s1)
    80003734:	893d                	andi	a0,a0,15
    80003736:	051a                	slli	a0,a0,0x6
    80003738:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000373a:	04449703          	lh	a4,68(s1)
    8000373e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003742:	04649703          	lh	a4,70(s1)
    80003746:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000374a:	04849703          	lh	a4,72(s1)
    8000374e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003752:	04a49703          	lh	a4,74(s1)
    80003756:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000375a:	44f8                	lw	a4,76(s1)
    8000375c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000375e:	03400613          	li	a2,52
    80003762:	05048593          	addi	a1,s1,80
    80003766:	0531                	addi	a0,a0,12
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	68a080e7          	jalr	1674(ra) # 80000df2 <memmove>
  log_write(bp);
    80003770:	854a                	mv	a0,s2
    80003772:	00001097          	auipc	ra,0x1
    80003776:	bee080e7          	jalr	-1042(ra) # 80004360 <log_write>
  brelse(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	980080e7          	jalr	-1664(ra) # 800030fc <brelse>
}
    80003784:	60e2                	ld	ra,24(sp)
    80003786:	6442                	ld	s0,16(sp)
    80003788:	64a2                	ld	s1,8(sp)
    8000378a:	6902                	ld	s2,0(sp)
    8000378c:	6105                	addi	sp,sp,32
    8000378e:	8082                	ret

0000000080003790 <idup>:
{
    80003790:	1101                	addi	sp,sp,-32
    80003792:	ec06                	sd	ra,24(sp)
    80003794:	e822                	sd	s0,16(sp)
    80003796:	e426                	sd	s1,8(sp)
    80003798:	1000                	addi	s0,sp,32
    8000379a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000379c:	0001d517          	auipc	a0,0x1d
    800037a0:	0c450513          	addi	a0,a0,196 # 80020860 <icache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	4f2080e7          	jalr	1266(ra) # 80000c96 <acquire>
  ip->ref++;
    800037ac:	449c                	lw	a5,8(s1)
    800037ae:	2785                	addiw	a5,a5,1
    800037b0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037b2:	0001d517          	auipc	a0,0x1d
    800037b6:	0ae50513          	addi	a0,a0,174 # 80020860 <icache>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	590080e7          	jalr	1424(ra) # 80000d4a <release>
}
    800037c2:	8526                	mv	a0,s1
    800037c4:	60e2                	ld	ra,24(sp)
    800037c6:	6442                	ld	s0,16(sp)
    800037c8:	64a2                	ld	s1,8(sp)
    800037ca:	6105                	addi	sp,sp,32
    800037cc:	8082                	ret

00000000800037ce <ilock>:
{
    800037ce:	1101                	addi	sp,sp,-32
    800037d0:	ec06                	sd	ra,24(sp)
    800037d2:	e822                	sd	s0,16(sp)
    800037d4:	e426                	sd	s1,8(sp)
    800037d6:	e04a                	sd	s2,0(sp)
    800037d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037da:	c115                	beqz	a0,800037fe <ilock+0x30>
    800037dc:	84aa                	mv	s1,a0
    800037de:	451c                	lw	a5,8(a0)
    800037e0:	00f05f63          	blez	a5,800037fe <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e4:	0541                	addi	a0,a0,16
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	ca2080e7          	jalr	-862(ra) # 80004488 <acquiresleep>
  if(ip->valid == 0){
    800037ee:	40bc                	lw	a5,64(s1)
    800037f0:	cf99                	beqz	a5,8000380e <ilock+0x40>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	addi	sp,sp,32
    800037fc:	8082                	ret
    panic("ilock");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	dfa50513          	addi	a0,a0,-518 # 800085f8 <syscalls+0x190>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	df2080e7          	jalr	-526(ra) # 800005f8 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380e:	40dc                	lw	a5,4(s1)
    80003810:	0047d79b          	srliw	a5,a5,0x4
    80003814:	0001d597          	auipc	a1,0x1d
    80003818:	0445a583          	lw	a1,68(a1) # 80020858 <sb+0x18>
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	4088                	lw	a0,0(s1)
    80003820:	fffff097          	auipc	ra,0xfffff
    80003824:	7ac080e7          	jalr	1964(ra) # 80002fcc <bread>
    80003828:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382a:	05850593          	addi	a1,a0,88
    8000382e:	40dc                	lw	a5,4(s1)
    80003830:	8bbd                	andi	a5,a5,15
    80003832:	079a                	slli	a5,a5,0x6
    80003834:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003836:	00059783          	lh	a5,0(a1)
    8000383a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000383e:	00259783          	lh	a5,2(a1)
    80003842:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003846:	00459783          	lh	a5,4(a1)
    8000384a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000384e:	00659783          	lh	a5,6(a1)
    80003852:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003856:	459c                	lw	a5,8(a1)
    80003858:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000385a:	03400613          	li	a2,52
    8000385e:	05b1                	addi	a1,a1,12
    80003860:	05048513          	addi	a0,s1,80
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	58e080e7          	jalr	1422(ra) # 80000df2 <memmove>
    brelse(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	88e080e7          	jalr	-1906(ra) # 800030fc <brelse>
    ip->valid = 1;
    80003876:	4785                	li	a5,1
    80003878:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000387a:	04449783          	lh	a5,68(s1)
    8000387e:	fbb5                	bnez	a5,800037f2 <ilock+0x24>
      panic("ilock: no type");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	d8050513          	addi	a0,a0,-640 # 80008600 <syscalls+0x198>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	d70080e7          	jalr	-656(ra) # 800005f8 <panic>

0000000080003890 <iunlock>:
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	e04a                	sd	s2,0(sp)
    8000389a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389c:	c905                	beqz	a0,800038cc <iunlock+0x3c>
    8000389e:	84aa                	mv	s1,a0
    800038a0:	01050913          	addi	s2,a0,16
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	c7c080e7          	jalr	-900(ra) # 80004522 <holdingsleep>
    800038ae:	cd19                	beqz	a0,800038cc <iunlock+0x3c>
    800038b0:	449c                	lw	a5,8(s1)
    800038b2:	00f05d63          	blez	a5,800038cc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b6:	854a                	mv	a0,s2
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	c26080e7          	jalr	-986(ra) # 800044de <releasesleep>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret
    panic("iunlock");
    800038cc:	00005517          	auipc	a0,0x5
    800038d0:	d4450513          	addi	a0,a0,-700 # 80008610 <syscalls+0x1a8>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	d24080e7          	jalr	-732(ra) # 800005f8 <panic>

00000000800038dc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038dc:	7179                	addi	sp,sp,-48
    800038de:	f406                	sd	ra,40(sp)
    800038e0:	f022                	sd	s0,32(sp)
    800038e2:	ec26                	sd	s1,24(sp)
    800038e4:	e84a                	sd	s2,16(sp)
    800038e6:	e44e                	sd	s3,8(sp)
    800038e8:	e052                	sd	s4,0(sp)
    800038ea:	1800                	addi	s0,sp,48
    800038ec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ee:	05050493          	addi	s1,a0,80
    800038f2:	08050913          	addi	s2,a0,128
    800038f6:	a021                	j	800038fe <itrunc+0x22>
    800038f8:	0491                	addi	s1,s1,4
    800038fa:	01248d63          	beq	s1,s2,80003914 <itrunc+0x38>
    if(ip->addrs[i]){
    800038fe:	408c                	lw	a1,0(s1)
    80003900:	dde5                	beqz	a1,800038f8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003902:	0009a503          	lw	a0,0(s3)
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	90c080e7          	jalr	-1780(ra) # 80003212 <bfree>
      ip->addrs[i] = 0;
    8000390e:	0004a023          	sw	zero,0(s1)
    80003912:	b7dd                	j	800038f8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003914:	0809a583          	lw	a1,128(s3)
    80003918:	e185                	bnez	a1,80003938 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000391a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000391e:	854e                	mv	a0,s3
    80003920:	00000097          	auipc	ra,0x0
    80003924:	de4080e7          	jalr	-540(ra) # 80003704 <iupdate>
}
    80003928:	70a2                	ld	ra,40(sp)
    8000392a:	7402                	ld	s0,32(sp)
    8000392c:	64e2                	ld	s1,24(sp)
    8000392e:	6942                	ld	s2,16(sp)
    80003930:	69a2                	ld	s3,8(sp)
    80003932:	6a02                	ld	s4,0(sp)
    80003934:	6145                	addi	sp,sp,48
    80003936:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	fffff097          	auipc	ra,0xfffff
    80003940:	690080e7          	jalr	1680(ra) # 80002fcc <bread>
    80003944:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003946:	05850493          	addi	s1,a0,88
    8000394a:	45850913          	addi	s2,a0,1112
    8000394e:	a811                	j	80003962 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003950:	0009a503          	lw	a0,0(s3)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	8be080e7          	jalr	-1858(ra) # 80003212 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395c:	0491                	addi	s1,s1,4
    8000395e:	01248563          	beq	s1,s2,80003968 <itrunc+0x8c>
      if(a[j])
    80003962:	408c                	lw	a1,0(s1)
    80003964:	dde5                	beqz	a1,8000395c <itrunc+0x80>
    80003966:	b7ed                	j	80003950 <itrunc+0x74>
    brelse(bp);
    80003968:	8552                	mv	a0,s4
    8000396a:	fffff097          	auipc	ra,0xfffff
    8000396e:	792080e7          	jalr	1938(ra) # 800030fc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003972:	0809a583          	lw	a1,128(s3)
    80003976:	0009a503          	lw	a0,0(s3)
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	898080e7          	jalr	-1896(ra) # 80003212 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003982:	0809a023          	sw	zero,128(s3)
    80003986:	bf51                	j	8000391a <itrunc+0x3e>

0000000080003988 <iput>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003996:	0001d517          	auipc	a0,0x1d
    8000399a:	eca50513          	addi	a0,a0,-310 # 80020860 <icache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	2f8080e7          	jalr	760(ra) # 80000c96 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a6:	4498                	lw	a4,8(s1)
    800039a8:	4785                	li	a5,1
    800039aa:	02f70363          	beq	a4,a5,800039d0 <iput+0x48>
  ip->ref--;
    800039ae:	449c                	lw	a5,8(s1)
    800039b0:	37fd                	addiw	a5,a5,-1
    800039b2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039b4:	0001d517          	auipc	a0,0x1d
    800039b8:	eac50513          	addi	a0,a0,-340 # 80020860 <icache>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	38e080e7          	jalr	910(ra) # 80000d4a <release>
}
    800039c4:	60e2                	ld	ra,24(sp)
    800039c6:	6442                	ld	s0,16(sp)
    800039c8:	64a2                	ld	s1,8(sp)
    800039ca:	6902                	ld	s2,0(sp)
    800039cc:	6105                	addi	sp,sp,32
    800039ce:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d0:	40bc                	lw	a5,64(s1)
    800039d2:	dff1                	beqz	a5,800039ae <iput+0x26>
    800039d4:	04a49783          	lh	a5,74(s1)
    800039d8:	fbf9                	bnez	a5,800039ae <iput+0x26>
    acquiresleep(&ip->lock);
    800039da:	01048913          	addi	s2,s1,16
    800039de:	854a                	mv	a0,s2
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	aa8080e7          	jalr	-1368(ra) # 80004488 <acquiresleep>
    release(&icache.lock);
    800039e8:	0001d517          	auipc	a0,0x1d
    800039ec:	e7850513          	addi	a0,a0,-392 # 80020860 <icache>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	35a080e7          	jalr	858(ra) # 80000d4a <release>
    itrunc(ip);
    800039f8:	8526                	mv	a0,s1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	ee2080e7          	jalr	-286(ra) # 800038dc <itrunc>
    ip->type = 0;
    80003a02:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a06:	8526                	mv	a0,s1
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	cfc080e7          	jalr	-772(ra) # 80003704 <iupdate>
    ip->valid = 0;
    80003a10:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	ac8080e7          	jalr	-1336(ra) # 800044de <releasesleep>
    acquire(&icache.lock);
    80003a1e:	0001d517          	auipc	a0,0x1d
    80003a22:	e4250513          	addi	a0,a0,-446 # 80020860 <icache>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	270080e7          	jalr	624(ra) # 80000c96 <acquire>
    80003a2e:	b741                	j	800039ae <iput+0x26>

0000000080003a30 <iunlockput>:
{
    80003a30:	1101                	addi	sp,sp,-32
    80003a32:	ec06                	sd	ra,24(sp)
    80003a34:	e822                	sd	s0,16(sp)
    80003a36:	e426                	sd	s1,8(sp)
    80003a38:	1000                	addi	s0,sp,32
    80003a3a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	e54080e7          	jalr	-428(ra) # 80003890 <iunlock>
  iput(ip);
    80003a44:	8526                	mv	a0,s1
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	f42080e7          	jalr	-190(ra) # 80003988 <iput>
}
    80003a4e:	60e2                	ld	ra,24(sp)
    80003a50:	6442                	ld	s0,16(sp)
    80003a52:	64a2                	ld	s1,8(sp)
    80003a54:	6105                	addi	sp,sp,32
    80003a56:	8082                	ret

0000000080003a58 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a58:	1141                	addi	sp,sp,-16
    80003a5a:	e422                	sd	s0,8(sp)
    80003a5c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a5e:	411c                	lw	a5,0(a0)
    80003a60:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a62:	415c                	lw	a5,4(a0)
    80003a64:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a66:	04451783          	lh	a5,68(a0)
    80003a6a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a6e:	04a51783          	lh	a5,74(a0)
    80003a72:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a76:	04c56783          	lwu	a5,76(a0)
    80003a7a:	e99c                	sd	a5,16(a1)
}
    80003a7c:	6422                	ld	s0,8(sp)
    80003a7e:	0141                	addi	sp,sp,16
    80003a80:	8082                	ret

0000000080003a82 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a82:	457c                	lw	a5,76(a0)
    80003a84:	0ed7e863          	bltu	a5,a3,80003b74 <readi+0xf2>
{
    80003a88:	7159                	addi	sp,sp,-112
    80003a8a:	f486                	sd	ra,104(sp)
    80003a8c:	f0a2                	sd	s0,96(sp)
    80003a8e:	eca6                	sd	s1,88(sp)
    80003a90:	e8ca                	sd	s2,80(sp)
    80003a92:	e4ce                	sd	s3,72(sp)
    80003a94:	e0d2                	sd	s4,64(sp)
    80003a96:	fc56                	sd	s5,56(sp)
    80003a98:	f85a                	sd	s6,48(sp)
    80003a9a:	f45e                	sd	s7,40(sp)
    80003a9c:	f062                	sd	s8,32(sp)
    80003a9e:	ec66                	sd	s9,24(sp)
    80003aa0:	e86a                	sd	s10,16(sp)
    80003aa2:	e46e                	sd	s11,8(sp)
    80003aa4:	1880                	addi	s0,sp,112
    80003aa6:	8baa                	mv	s7,a0
    80003aa8:	8c2e                	mv	s8,a1
    80003aaa:	8ab2                	mv	s5,a2
    80003aac:	84b6                	mv	s1,a3
    80003aae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ab0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab4:	08d76f63          	bltu	a4,a3,80003b52 <readi+0xd0>
  if(off + n > ip->size)
    80003ab8:	00e7f463          	bgeu	a5,a4,80003ac0 <readi+0x3e>
    n = ip->size - off;
    80003abc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac0:	0a0b0863          	beqz	s6,80003b70 <readi+0xee>
    80003ac4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aca:	5cfd                	li	s9,-1
    80003acc:	a82d                	j	80003b06 <readi+0x84>
    80003ace:	020a1d93          	slli	s11,s4,0x20
    80003ad2:	020ddd93          	srli	s11,s11,0x20
    80003ad6:	05890613          	addi	a2,s2,88
    80003ada:	86ee                	mv	a3,s11
    80003adc:	963a                	add	a2,a2,a4
    80003ade:	85d6                	mv	a1,s5
    80003ae0:	8562                	mv	a0,s8
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	a4a080e7          	jalr	-1462(ra) # 8000252c <either_copyout>
    80003aea:	05950d63          	beq	a0,s9,80003b44 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003aee:	854a                	mv	a0,s2
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	60c080e7          	jalr	1548(ra) # 800030fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af8:	013a09bb          	addw	s3,s4,s3
    80003afc:	009a04bb          	addw	s1,s4,s1
    80003b00:	9aee                	add	s5,s5,s11
    80003b02:	0569f663          	bgeu	s3,s6,80003b4e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b06:	000ba903          	lw	s2,0(s7)
    80003b0a:	00a4d59b          	srliw	a1,s1,0xa
    80003b0e:	855e                	mv	a0,s7
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	8b0080e7          	jalr	-1872(ra) # 800033c0 <bmap>
    80003b18:	0005059b          	sext.w	a1,a0
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	fffff097          	auipc	ra,0xfffff
    80003b22:	4ae080e7          	jalr	1198(ra) # 80002fcc <bread>
    80003b26:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	3ff4f713          	andi	a4,s1,1023
    80003b2c:	40ed07bb          	subw	a5,s10,a4
    80003b30:	413b06bb          	subw	a3,s6,s3
    80003b34:	8a3e                	mv	s4,a5
    80003b36:	2781                	sext.w	a5,a5
    80003b38:	0006861b          	sext.w	a2,a3
    80003b3c:	f8f679e3          	bgeu	a2,a5,80003ace <readi+0x4c>
    80003b40:	8a36                	mv	s4,a3
    80003b42:	b771                	j	80003ace <readi+0x4c>
      brelse(bp);
    80003b44:	854a                	mv	a0,s2
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	5b6080e7          	jalr	1462(ra) # 800030fc <brelse>
  }
  return tot;
    80003b4e:	0009851b          	sext.w	a0,s3
}
    80003b52:	70a6                	ld	ra,104(sp)
    80003b54:	7406                	ld	s0,96(sp)
    80003b56:	64e6                	ld	s1,88(sp)
    80003b58:	6946                	ld	s2,80(sp)
    80003b5a:	69a6                	ld	s3,72(sp)
    80003b5c:	6a06                	ld	s4,64(sp)
    80003b5e:	7ae2                	ld	s5,56(sp)
    80003b60:	7b42                	ld	s6,48(sp)
    80003b62:	7ba2                	ld	s7,40(sp)
    80003b64:	7c02                	ld	s8,32(sp)
    80003b66:	6ce2                	ld	s9,24(sp)
    80003b68:	6d42                	ld	s10,16(sp)
    80003b6a:	6da2                	ld	s11,8(sp)
    80003b6c:	6165                	addi	sp,sp,112
    80003b6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b70:	89da                	mv	s3,s6
    80003b72:	bff1                	j	80003b4e <readi+0xcc>
    return 0;
    80003b74:	4501                	li	a0,0
}
    80003b76:	8082                	ret

0000000080003b78 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b78:	457c                	lw	a5,76(a0)
    80003b7a:	10d7e663          	bltu	a5,a3,80003c86 <writei+0x10e>
{
    80003b7e:	7159                	addi	sp,sp,-112
    80003b80:	f486                	sd	ra,104(sp)
    80003b82:	f0a2                	sd	s0,96(sp)
    80003b84:	eca6                	sd	s1,88(sp)
    80003b86:	e8ca                	sd	s2,80(sp)
    80003b88:	e4ce                	sd	s3,72(sp)
    80003b8a:	e0d2                	sd	s4,64(sp)
    80003b8c:	fc56                	sd	s5,56(sp)
    80003b8e:	f85a                	sd	s6,48(sp)
    80003b90:	f45e                	sd	s7,40(sp)
    80003b92:	f062                	sd	s8,32(sp)
    80003b94:	ec66                	sd	s9,24(sp)
    80003b96:	e86a                	sd	s10,16(sp)
    80003b98:	e46e                	sd	s11,8(sp)
    80003b9a:	1880                	addi	s0,sp,112
    80003b9c:	8baa                	mv	s7,a0
    80003b9e:	8c2e                	mv	s8,a1
    80003ba0:	8ab2                	mv	s5,a2
    80003ba2:	8936                	mv	s2,a3
    80003ba4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba6:	00e687bb          	addw	a5,a3,a4
    80003baa:	0ed7e063          	bltu	a5,a3,80003c8a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bae:	00043737          	lui	a4,0x43
    80003bb2:	0cf76e63          	bltu	a4,a5,80003c8e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb6:	0a0b0763          	beqz	s6,80003c64 <writei+0xec>
    80003bba:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bbc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc0:	5cfd                	li	s9,-1
    80003bc2:	a091                	j	80003c06 <writei+0x8e>
    80003bc4:	02099d93          	slli	s11,s3,0x20
    80003bc8:	020ddd93          	srli	s11,s11,0x20
    80003bcc:	05848513          	addi	a0,s1,88
    80003bd0:	86ee                	mv	a3,s11
    80003bd2:	8656                	mv	a2,s5
    80003bd4:	85e2                	mv	a1,s8
    80003bd6:	953a                	add	a0,a0,a4
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	9aa080e7          	jalr	-1622(ra) # 80002582 <either_copyin>
    80003be0:	07950263          	beq	a0,s9,80003c44 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be4:	8526                	mv	a0,s1
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	77a080e7          	jalr	1914(ra) # 80004360 <log_write>
    brelse(bp);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	50c080e7          	jalr	1292(ra) # 800030fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf8:	01498a3b          	addw	s4,s3,s4
    80003bfc:	0129893b          	addw	s2,s3,s2
    80003c00:	9aee                	add	s5,s5,s11
    80003c02:	056a7663          	bgeu	s4,s6,80003c4e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c06:	000ba483          	lw	s1,0(s7)
    80003c0a:	00a9559b          	srliw	a1,s2,0xa
    80003c0e:	855e                	mv	a0,s7
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	7b0080e7          	jalr	1968(ra) # 800033c0 <bmap>
    80003c18:	0005059b          	sext.w	a1,a0
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	3ae080e7          	jalr	942(ra) # 80002fcc <bread>
    80003c26:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c28:	3ff97713          	andi	a4,s2,1023
    80003c2c:	40ed07bb          	subw	a5,s10,a4
    80003c30:	414b06bb          	subw	a3,s6,s4
    80003c34:	89be                	mv	s3,a5
    80003c36:	2781                	sext.w	a5,a5
    80003c38:	0006861b          	sext.w	a2,a3
    80003c3c:	f8f674e3          	bgeu	a2,a5,80003bc4 <writei+0x4c>
    80003c40:	89b6                	mv	s3,a3
    80003c42:	b749                	j	80003bc4 <writei+0x4c>
      brelse(bp);
    80003c44:	8526                	mv	a0,s1
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	4b6080e7          	jalr	1206(ra) # 800030fc <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c4e:	04cba783          	lw	a5,76(s7)
    80003c52:	0127f463          	bgeu	a5,s2,80003c5a <writei+0xe2>
      ip->size = off;
    80003c56:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c5a:	855e                	mv	a0,s7
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	aa8080e7          	jalr	-1368(ra) # 80003704 <iupdate>
  }

  return n;
    80003c64:	000b051b          	sext.w	a0,s6
}
    80003c68:	70a6                	ld	ra,104(sp)
    80003c6a:	7406                	ld	s0,96(sp)
    80003c6c:	64e6                	ld	s1,88(sp)
    80003c6e:	6946                	ld	s2,80(sp)
    80003c70:	69a6                	ld	s3,72(sp)
    80003c72:	6a06                	ld	s4,64(sp)
    80003c74:	7ae2                	ld	s5,56(sp)
    80003c76:	7b42                	ld	s6,48(sp)
    80003c78:	7ba2                	ld	s7,40(sp)
    80003c7a:	7c02                	ld	s8,32(sp)
    80003c7c:	6ce2                	ld	s9,24(sp)
    80003c7e:	6d42                	ld	s10,16(sp)
    80003c80:	6da2                	ld	s11,8(sp)
    80003c82:	6165                	addi	sp,sp,112
    80003c84:	8082                	ret
    return -1;
    80003c86:	557d                	li	a0,-1
}
    80003c88:	8082                	ret
    return -1;
    80003c8a:	557d                	li	a0,-1
    80003c8c:	bff1                	j	80003c68 <writei+0xf0>
    return -1;
    80003c8e:	557d                	li	a0,-1
    80003c90:	bfe1                	j	80003c68 <writei+0xf0>

0000000080003c92 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c92:	1141                	addi	sp,sp,-16
    80003c94:	e406                	sd	ra,8(sp)
    80003c96:	e022                	sd	s0,0(sp)
    80003c98:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c9a:	4639                	li	a2,14
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	1d2080e7          	jalr	466(ra) # 80000e6e <strncmp>
}
    80003ca4:	60a2                	ld	ra,8(sp)
    80003ca6:	6402                	ld	s0,0(sp)
    80003ca8:	0141                	addi	sp,sp,16
    80003caa:	8082                	ret

0000000080003cac <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cac:	7139                	addi	sp,sp,-64
    80003cae:	fc06                	sd	ra,56(sp)
    80003cb0:	f822                	sd	s0,48(sp)
    80003cb2:	f426                	sd	s1,40(sp)
    80003cb4:	f04a                	sd	s2,32(sp)
    80003cb6:	ec4e                	sd	s3,24(sp)
    80003cb8:	e852                	sd	s4,16(sp)
    80003cba:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cbc:	04451703          	lh	a4,68(a0)
    80003cc0:	4785                	li	a5,1
    80003cc2:	00f71a63          	bne	a4,a5,80003cd6 <dirlookup+0x2a>
    80003cc6:	892a                	mv	s2,a0
    80003cc8:	89ae                	mv	s3,a1
    80003cca:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ccc:	457c                	lw	a5,76(a0)
    80003cce:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd2:	e79d                	bnez	a5,80003d00 <dirlookup+0x54>
    80003cd4:	a8a5                	j	80003d4c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	94250513          	addi	a0,a0,-1726 # 80008618 <syscalls+0x1b0>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	91a080e7          	jalr	-1766(ra) # 800005f8 <panic>
      panic("dirlookup read");
    80003ce6:	00005517          	auipc	a0,0x5
    80003cea:	94a50513          	addi	a0,a0,-1718 # 80008630 <syscalls+0x1c8>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	90a080e7          	jalr	-1782(ra) # 800005f8 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf6:	24c1                	addiw	s1,s1,16
    80003cf8:	04c92783          	lw	a5,76(s2)
    80003cfc:	04f4f763          	bgeu	s1,a5,80003d4a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d00:	4741                	li	a4,16
    80003d02:	86a6                	mv	a3,s1
    80003d04:	fc040613          	addi	a2,s0,-64
    80003d08:	4581                	li	a1,0
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	d76080e7          	jalr	-650(ra) # 80003a82 <readi>
    80003d14:	47c1                	li	a5,16
    80003d16:	fcf518e3          	bne	a0,a5,80003ce6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d1a:	fc045783          	lhu	a5,-64(s0)
    80003d1e:	dfe1                	beqz	a5,80003cf6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d20:	fc240593          	addi	a1,s0,-62
    80003d24:	854e                	mv	a0,s3
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	f6c080e7          	jalr	-148(ra) # 80003c92 <namecmp>
    80003d2e:	f561                	bnez	a0,80003cf6 <dirlookup+0x4a>
      if(poff)
    80003d30:	000a0463          	beqz	s4,80003d38 <dirlookup+0x8c>
        *poff = off;
    80003d34:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d38:	fc045583          	lhu	a1,-64(s0)
    80003d3c:	00092503          	lw	a0,0(s2)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	75a080e7          	jalr	1882(ra) # 8000349a <iget>
    80003d48:	a011                	j	80003d4c <dirlookup+0xa0>
  return 0;
    80003d4a:	4501                	li	a0,0
}
    80003d4c:	70e2                	ld	ra,56(sp)
    80003d4e:	7442                	ld	s0,48(sp)
    80003d50:	74a2                	ld	s1,40(sp)
    80003d52:	7902                	ld	s2,32(sp)
    80003d54:	69e2                	ld	s3,24(sp)
    80003d56:	6a42                	ld	s4,16(sp)
    80003d58:	6121                	addi	sp,sp,64
    80003d5a:	8082                	ret

0000000080003d5c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d5c:	711d                	addi	sp,sp,-96
    80003d5e:	ec86                	sd	ra,88(sp)
    80003d60:	e8a2                	sd	s0,80(sp)
    80003d62:	e4a6                	sd	s1,72(sp)
    80003d64:	e0ca                	sd	s2,64(sp)
    80003d66:	fc4e                	sd	s3,56(sp)
    80003d68:	f852                	sd	s4,48(sp)
    80003d6a:	f456                	sd	s5,40(sp)
    80003d6c:	f05a                	sd	s6,32(sp)
    80003d6e:	ec5e                	sd	s7,24(sp)
    80003d70:	e862                	sd	s8,16(sp)
    80003d72:	e466                	sd	s9,8(sp)
    80003d74:	1080                	addi	s0,sp,96
    80003d76:	84aa                	mv	s1,a0
    80003d78:	8b2e                	mv	s6,a1
    80003d7a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d7c:	00054703          	lbu	a4,0(a0)
    80003d80:	02f00793          	li	a5,47
    80003d84:	02f70363          	beq	a4,a5,80003daa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d88:	ffffe097          	auipc	ra,0xffffe
    80003d8c:	cdc080e7          	jalr	-804(ra) # 80001a64 <myproc>
    80003d90:	15053503          	ld	a0,336(a0)
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	9fc080e7          	jalr	-1540(ra) # 80003790 <idup>
    80003d9c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d9e:	02f00913          	li	s2,47
  len = path - s;
    80003da2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003da4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da6:	4c05                	li	s8,1
    80003da8:	a865                	j	80003e60 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003daa:	4585                	li	a1,1
    80003dac:	4505                	li	a0,1
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	6ec080e7          	jalr	1772(ra) # 8000349a <iget>
    80003db6:	89aa                	mv	s3,a0
    80003db8:	b7dd                	j	80003d9e <namex+0x42>
      iunlockput(ip);
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	c74080e7          	jalr	-908(ra) # 80003a30 <iunlockput>
      return 0;
    80003dc4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	60e6                	ld	ra,88(sp)
    80003dca:	6446                	ld	s0,80(sp)
    80003dcc:	64a6                	ld	s1,72(sp)
    80003dce:	6906                	ld	s2,64(sp)
    80003dd0:	79e2                	ld	s3,56(sp)
    80003dd2:	7a42                	ld	s4,48(sp)
    80003dd4:	7aa2                	ld	s5,40(sp)
    80003dd6:	7b02                	ld	s6,32(sp)
    80003dd8:	6be2                	ld	s7,24(sp)
    80003dda:	6c42                	ld	s8,16(sp)
    80003ddc:	6ca2                	ld	s9,8(sp)
    80003dde:	6125                	addi	sp,sp,96
    80003de0:	8082                	ret
      iunlock(ip);
    80003de2:	854e                	mv	a0,s3
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	aac080e7          	jalr	-1364(ra) # 80003890 <iunlock>
      return ip;
    80003dec:	bfe9                	j	80003dc6 <namex+0x6a>
      iunlockput(ip);
    80003dee:	854e                	mv	a0,s3
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	c40080e7          	jalr	-960(ra) # 80003a30 <iunlockput>
      return 0;
    80003df8:	89d2                	mv	s3,s4
    80003dfa:	b7f1                	j	80003dc6 <namex+0x6a>
  len = path - s;
    80003dfc:	40b48633          	sub	a2,s1,a1
    80003e00:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e04:	094cd463          	bge	s9,s4,80003e8c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e08:	4639                	li	a2,14
    80003e0a:	8556                	mv	a0,s5
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	fe6080e7          	jalr	-26(ra) # 80000df2 <memmove>
  while(*path == '/')
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	01279763          	bne	a5,s2,80003e26 <namex+0xca>
    path++;
    80003e1c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e1e:	0004c783          	lbu	a5,0(s1)
    80003e22:	ff278de3          	beq	a5,s2,80003e1c <namex+0xc0>
    ilock(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	9a6080e7          	jalr	-1626(ra) # 800037ce <ilock>
    if(ip->type != T_DIR){
    80003e30:	04499783          	lh	a5,68(s3)
    80003e34:	f98793e3          	bne	a5,s8,80003dba <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e38:	000b0563          	beqz	s6,80003e42 <namex+0xe6>
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	d3cd                	beqz	a5,80003de2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e42:	865e                	mv	a2,s7
    80003e44:	85d6                	mv	a1,s5
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	e64080e7          	jalr	-412(ra) # 80003cac <dirlookup>
    80003e50:	8a2a                	mv	s4,a0
    80003e52:	dd51                	beqz	a0,80003dee <namex+0x92>
    iunlockput(ip);
    80003e54:	854e                	mv	a0,s3
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	bda080e7          	jalr	-1062(ra) # 80003a30 <iunlockput>
    ip = next;
    80003e5e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e60:	0004c783          	lbu	a5,0(s1)
    80003e64:	05279763          	bne	a5,s2,80003eb2 <namex+0x156>
    path++;
    80003e68:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e6a:	0004c783          	lbu	a5,0(s1)
    80003e6e:	ff278de3          	beq	a5,s2,80003e68 <namex+0x10c>
  if(*path == 0)
    80003e72:	c79d                	beqz	a5,80003ea0 <namex+0x144>
    path++;
    80003e74:	85a6                	mv	a1,s1
  len = path - s;
    80003e76:	8a5e                	mv	s4,s7
    80003e78:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e7a:	01278963          	beq	a5,s2,80003e8c <namex+0x130>
    80003e7e:	dfbd                	beqz	a5,80003dfc <namex+0xa0>
    path++;
    80003e80:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	ff279ce3          	bne	a5,s2,80003e7e <namex+0x122>
    80003e8a:	bf8d                	j	80003dfc <namex+0xa0>
    memmove(name, s, len);
    80003e8c:	2601                	sext.w	a2,a2
    80003e8e:	8556                	mv	a0,s5
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	f62080e7          	jalr	-158(ra) # 80000df2 <memmove>
    name[len] = 0;
    80003e98:	9a56                	add	s4,s4,s5
    80003e9a:	000a0023          	sb	zero,0(s4)
    80003e9e:	bf9d                	j	80003e14 <namex+0xb8>
  if(nameiparent){
    80003ea0:	f20b03e3          	beqz	s6,80003dc6 <namex+0x6a>
    iput(ip);
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	ae2080e7          	jalr	-1310(ra) # 80003988 <iput>
    return 0;
    80003eae:	4981                	li	s3,0
    80003eb0:	bf19                	j	80003dc6 <namex+0x6a>
  if(*path == 0)
    80003eb2:	d7fd                	beqz	a5,80003ea0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	85a6                	mv	a1,s1
    80003eba:	b7d1                	j	80003e7e <namex+0x122>

0000000080003ebc <dirlink>:
{
    80003ebc:	7139                	addi	sp,sp,-64
    80003ebe:	fc06                	sd	ra,56(sp)
    80003ec0:	f822                	sd	s0,48(sp)
    80003ec2:	f426                	sd	s1,40(sp)
    80003ec4:	f04a                	sd	s2,32(sp)
    80003ec6:	ec4e                	sd	s3,24(sp)
    80003ec8:	e852                	sd	s4,16(sp)
    80003eca:	0080                	addi	s0,sp,64
    80003ecc:	892a                	mv	s2,a0
    80003ece:	8a2e                	mv	s4,a1
    80003ed0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed2:	4601                	li	a2,0
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	dd8080e7          	jalr	-552(ra) # 80003cac <dirlookup>
    80003edc:	e93d                	bnez	a0,80003f52 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ede:	04c92483          	lw	s1,76(s2)
    80003ee2:	c49d                	beqz	s1,80003f10 <dirlink+0x54>
    80003ee4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	4741                	li	a4,16
    80003ee8:	86a6                	mv	a3,s1
    80003eea:	fc040613          	addi	a2,s0,-64
    80003eee:	4581                	li	a1,0
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	b90080e7          	jalr	-1136(ra) # 80003a82 <readi>
    80003efa:	47c1                	li	a5,16
    80003efc:	06f51163          	bne	a0,a5,80003f5e <dirlink+0xa2>
    if(de.inum == 0)
    80003f00:	fc045783          	lhu	a5,-64(s0)
    80003f04:	c791                	beqz	a5,80003f10 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f06:	24c1                	addiw	s1,s1,16
    80003f08:	04c92783          	lw	a5,76(s2)
    80003f0c:	fcf4ede3          	bltu	s1,a5,80003ee6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f10:	4639                	li	a2,14
    80003f12:	85d2                	mv	a1,s4
    80003f14:	fc240513          	addi	a0,s0,-62
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	f92080e7          	jalr	-110(ra) # 80000eaa <strncpy>
  de.inum = inum;
    80003f20:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f24:	4741                	li	a4,16
    80003f26:	86a6                	mv	a3,s1
    80003f28:	fc040613          	addi	a2,s0,-64
    80003f2c:	4581                	li	a1,0
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	c48080e7          	jalr	-952(ra) # 80003b78 <writei>
    80003f38:	872a                	mv	a4,a0
    80003f3a:	47c1                	li	a5,16
  return 0;
    80003f3c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3e:	02f71863          	bne	a4,a5,80003f6e <dirlink+0xb2>
}
    80003f42:	70e2                	ld	ra,56(sp)
    80003f44:	7442                	ld	s0,48(sp)
    80003f46:	74a2                	ld	s1,40(sp)
    80003f48:	7902                	ld	s2,32(sp)
    80003f4a:	69e2                	ld	s3,24(sp)
    80003f4c:	6a42                	ld	s4,16(sp)
    80003f4e:	6121                	addi	sp,sp,64
    80003f50:	8082                	ret
    iput(ip);
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	a36080e7          	jalr	-1482(ra) # 80003988 <iput>
    return -1;
    80003f5a:	557d                	li	a0,-1
    80003f5c:	b7dd                	j	80003f42 <dirlink+0x86>
      panic("dirlink read");
    80003f5e:	00004517          	auipc	a0,0x4
    80003f62:	6e250513          	addi	a0,a0,1762 # 80008640 <syscalls+0x1d8>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	692080e7          	jalr	1682(ra) # 800005f8 <panic>
    panic("dirlink");
    80003f6e:	00004517          	auipc	a0,0x4
    80003f72:	7f250513          	addi	a0,a0,2034 # 80008760 <syscalls+0x2f8>
    80003f76:	ffffc097          	auipc	ra,0xffffc
    80003f7a:	682080e7          	jalr	1666(ra) # 800005f8 <panic>

0000000080003f7e <namei>:

struct inode*
namei(char *path)
{
    80003f7e:	1101                	addi	sp,sp,-32
    80003f80:	ec06                	sd	ra,24(sp)
    80003f82:	e822                	sd	s0,16(sp)
    80003f84:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f86:	fe040613          	addi	a2,s0,-32
    80003f8a:	4581                	li	a1,0
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	dd0080e7          	jalr	-560(ra) # 80003d5c <namex>
}
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	6105                	addi	sp,sp,32
    80003f9a:	8082                	ret

0000000080003f9c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f9c:	1141                	addi	sp,sp,-16
    80003f9e:	e406                	sd	ra,8(sp)
    80003fa0:	e022                	sd	s0,0(sp)
    80003fa2:	0800                	addi	s0,sp,16
    80003fa4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fa6:	4585                	li	a1,1
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	db4080e7          	jalr	-588(ra) # 80003d5c <namex>
}
    80003fb0:	60a2                	ld	ra,8(sp)
    80003fb2:	6402                	ld	s0,0(sp)
    80003fb4:	0141                	addi	sp,sp,16
    80003fb6:	8082                	ret

0000000080003fb8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb8:	1101                	addi	sp,sp,-32
    80003fba:	ec06                	sd	ra,24(sp)
    80003fbc:	e822                	sd	s0,16(sp)
    80003fbe:	e426                	sd	s1,8(sp)
    80003fc0:	e04a                	sd	s2,0(sp)
    80003fc2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fc4:	0001e917          	auipc	s2,0x1e
    80003fc8:	34490913          	addi	s2,s2,836 # 80022308 <log>
    80003fcc:	01892583          	lw	a1,24(s2)
    80003fd0:	02892503          	lw	a0,40(s2)
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	ff8080e7          	jalr	-8(ra) # 80002fcc <bread>
    80003fdc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fde:	02c92683          	lw	a3,44(s2)
    80003fe2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fe4:	02d05763          	blez	a3,80004012 <write_head+0x5a>
    80003fe8:	0001e797          	auipc	a5,0x1e
    80003fec:	35078793          	addi	a5,a5,848 # 80022338 <log+0x30>
    80003ff0:	05c50713          	addi	a4,a0,92
    80003ff4:	36fd                	addiw	a3,a3,-1
    80003ff6:	1682                	slli	a3,a3,0x20
    80003ff8:	9281                	srli	a3,a3,0x20
    80003ffa:	068a                	slli	a3,a3,0x2
    80003ffc:	0001e617          	auipc	a2,0x1e
    80004000:	34060613          	addi	a2,a2,832 # 8002233c <log+0x34>
    80004004:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004006:	4390                	lw	a2,0(a5)
    80004008:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000400a:	0791                	addi	a5,a5,4
    8000400c:	0711                	addi	a4,a4,4
    8000400e:	fed79ce3          	bne	a5,a3,80004006 <write_head+0x4e>
  }
  bwrite(buf);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	0aa080e7          	jalr	170(ra) # 800030be <bwrite>
  brelse(buf);
    8000401c:	8526                	mv	a0,s1
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	0de080e7          	jalr	222(ra) # 800030fc <brelse>
}
    80004026:	60e2                	ld	ra,24(sp)
    80004028:	6442                	ld	s0,16(sp)
    8000402a:	64a2                	ld	s1,8(sp)
    8000402c:	6902                	ld	s2,0(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004032:	0001e797          	auipc	a5,0x1e
    80004036:	3027a783          	lw	a5,770(a5) # 80022334 <log+0x2c>
    8000403a:	0af05663          	blez	a5,800040e6 <install_trans+0xb4>
{
    8000403e:	7139                	addi	sp,sp,-64
    80004040:	fc06                	sd	ra,56(sp)
    80004042:	f822                	sd	s0,48(sp)
    80004044:	f426                	sd	s1,40(sp)
    80004046:	f04a                	sd	s2,32(sp)
    80004048:	ec4e                	sd	s3,24(sp)
    8000404a:	e852                	sd	s4,16(sp)
    8000404c:	e456                	sd	s5,8(sp)
    8000404e:	0080                	addi	s0,sp,64
    80004050:	0001ea97          	auipc	s5,0x1e
    80004054:	2e8a8a93          	addi	s5,s5,744 # 80022338 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004058:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000405a:	0001e997          	auipc	s3,0x1e
    8000405e:	2ae98993          	addi	s3,s3,686 # 80022308 <log>
    80004062:	0189a583          	lw	a1,24(s3)
    80004066:	014585bb          	addw	a1,a1,s4
    8000406a:	2585                	addiw	a1,a1,1
    8000406c:	0289a503          	lw	a0,40(s3)
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	f5c080e7          	jalr	-164(ra) # 80002fcc <bread>
    80004078:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000407a:	000aa583          	lw	a1,0(s5)
    8000407e:	0289a503          	lw	a0,40(s3)
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	f4a080e7          	jalr	-182(ra) # 80002fcc <bread>
    8000408a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000408c:	40000613          	li	a2,1024
    80004090:	05890593          	addi	a1,s2,88
    80004094:	05850513          	addi	a0,a0,88
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	d5a080e7          	jalr	-678(ra) # 80000df2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040a0:	8526                	mv	a0,s1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	01c080e7          	jalr	28(ra) # 800030be <bwrite>
    bunpin(dbuf);
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	12a080e7          	jalr	298(ra) # 800031d6 <bunpin>
    brelse(lbuf);
    800040b4:	854a                	mv	a0,s2
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	046080e7          	jalr	70(ra) # 800030fc <brelse>
    brelse(dbuf);
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	03c080e7          	jalr	60(ra) # 800030fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c8:	2a05                	addiw	s4,s4,1
    800040ca:	0a91                	addi	s5,s5,4
    800040cc:	02c9a783          	lw	a5,44(s3)
    800040d0:	f8fa49e3          	blt	s4,a5,80004062 <install_trans+0x30>
}
    800040d4:	70e2                	ld	ra,56(sp)
    800040d6:	7442                	ld	s0,48(sp)
    800040d8:	74a2                	ld	s1,40(sp)
    800040da:	7902                	ld	s2,32(sp)
    800040dc:	69e2                	ld	s3,24(sp)
    800040de:	6a42                	ld	s4,16(sp)
    800040e0:	6aa2                	ld	s5,8(sp)
    800040e2:	6121                	addi	sp,sp,64
    800040e4:	8082                	ret
    800040e6:	8082                	ret

00000000800040e8 <initlog>:
{
    800040e8:	7179                	addi	sp,sp,-48
    800040ea:	f406                	sd	ra,40(sp)
    800040ec:	f022                	sd	s0,32(sp)
    800040ee:	ec26                	sd	s1,24(sp)
    800040f0:	e84a                	sd	s2,16(sp)
    800040f2:	e44e                	sd	s3,8(sp)
    800040f4:	1800                	addi	s0,sp,48
    800040f6:	892a                	mv	s2,a0
    800040f8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040fa:	0001e497          	auipc	s1,0x1e
    800040fe:	20e48493          	addi	s1,s1,526 # 80022308 <log>
    80004102:	00004597          	auipc	a1,0x4
    80004106:	54e58593          	addi	a1,a1,1358 # 80008650 <syscalls+0x1e8>
    8000410a:	8526                	mv	a0,s1
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	afa080e7          	jalr	-1286(ra) # 80000c06 <initlock>
  log.start = sb->logstart;
    80004114:	0149a583          	lw	a1,20(s3)
    80004118:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000411a:	0109a783          	lw	a5,16(s3)
    8000411e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004120:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004124:	854a                	mv	a0,s2
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	ea6080e7          	jalr	-346(ra) # 80002fcc <bread>
  log.lh.n = lh->n;
    8000412e:	4d3c                	lw	a5,88(a0)
    80004130:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004132:	02f05563          	blez	a5,8000415c <initlog+0x74>
    80004136:	05c50713          	addi	a4,a0,92
    8000413a:	0001e697          	auipc	a3,0x1e
    8000413e:	1fe68693          	addi	a3,a3,510 # 80022338 <log+0x30>
    80004142:	37fd                	addiw	a5,a5,-1
    80004144:	1782                	slli	a5,a5,0x20
    80004146:	9381                	srli	a5,a5,0x20
    80004148:	078a                	slli	a5,a5,0x2
    8000414a:	06050613          	addi	a2,a0,96
    8000414e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004150:	4310                	lw	a2,0(a4)
    80004152:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004154:	0711                	addi	a4,a4,4
    80004156:	0691                	addi	a3,a3,4
    80004158:	fef71ce3          	bne	a4,a5,80004150 <initlog+0x68>
  brelse(buf);
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	fa0080e7          	jalr	-96(ra) # 800030fc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004164:	00000097          	auipc	ra,0x0
    80004168:	ece080e7          	jalr	-306(ra) # 80004032 <install_trans>
  log.lh.n = 0;
    8000416c:	0001e797          	auipc	a5,0x1e
    80004170:	1c07a423          	sw	zero,456(a5) # 80022334 <log+0x2c>
  write_head(); // clear the log
    80004174:	00000097          	auipc	ra,0x0
    80004178:	e44080e7          	jalr	-444(ra) # 80003fb8 <write_head>
}
    8000417c:	70a2                	ld	ra,40(sp)
    8000417e:	7402                	ld	s0,32(sp)
    80004180:	64e2                	ld	s1,24(sp)
    80004182:	6942                	ld	s2,16(sp)
    80004184:	69a2                	ld	s3,8(sp)
    80004186:	6145                	addi	sp,sp,48
    80004188:	8082                	ret

000000008000418a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	e04a                	sd	s2,0(sp)
    80004194:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004196:	0001e517          	auipc	a0,0x1e
    8000419a:	17250513          	addi	a0,a0,370 # 80022308 <log>
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	af8080e7          	jalr	-1288(ra) # 80000c96 <acquire>
  while(1){
    if(log.committing){
    800041a6:	0001e497          	auipc	s1,0x1e
    800041aa:	16248493          	addi	s1,s1,354 # 80022308 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ae:	4979                	li	s2,30
    800041b0:	a039                	j	800041be <begin_op+0x34>
      sleep(&log, &log.lock);
    800041b2:	85a6                	mv	a1,s1
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffe097          	auipc	ra,0xffffe
    800041ba:	114080e7          	jalr	276(ra) # 800022ca <sleep>
    if(log.committing){
    800041be:	50dc                	lw	a5,36(s1)
    800041c0:	fbed                	bnez	a5,800041b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c2:	509c                	lw	a5,32(s1)
    800041c4:	0017871b          	addiw	a4,a5,1
    800041c8:	0007069b          	sext.w	a3,a4
    800041cc:	0027179b          	slliw	a5,a4,0x2
    800041d0:	9fb9                	addw	a5,a5,a4
    800041d2:	0017979b          	slliw	a5,a5,0x1
    800041d6:	54d8                	lw	a4,44(s1)
    800041d8:	9fb9                	addw	a5,a5,a4
    800041da:	00f95963          	bge	s2,a5,800041ec <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041de:	85a6                	mv	a1,s1
    800041e0:	8526                	mv	a0,s1
    800041e2:	ffffe097          	auipc	ra,0xffffe
    800041e6:	0e8080e7          	jalr	232(ra) # 800022ca <sleep>
    800041ea:	bfd1                	j	800041be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ec:	0001e517          	auipc	a0,0x1e
    800041f0:	11c50513          	addi	a0,a0,284 # 80022308 <log>
    800041f4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	b54080e7          	jalr	-1196(ra) # 80000d4a <release>
      break;
    }
  }
}
    800041fe:	60e2                	ld	ra,24(sp)
    80004200:	6442                	ld	s0,16(sp)
    80004202:	64a2                	ld	s1,8(sp)
    80004204:	6902                	ld	s2,0(sp)
    80004206:	6105                	addi	sp,sp,32
    80004208:	8082                	ret

000000008000420a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000420a:	7139                	addi	sp,sp,-64
    8000420c:	fc06                	sd	ra,56(sp)
    8000420e:	f822                	sd	s0,48(sp)
    80004210:	f426                	sd	s1,40(sp)
    80004212:	f04a                	sd	s2,32(sp)
    80004214:	ec4e                	sd	s3,24(sp)
    80004216:	e852                	sd	s4,16(sp)
    80004218:	e456                	sd	s5,8(sp)
    8000421a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000421c:	0001e497          	auipc	s1,0x1e
    80004220:	0ec48493          	addi	s1,s1,236 # 80022308 <log>
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	a70080e7          	jalr	-1424(ra) # 80000c96 <acquire>
  log.outstanding -= 1;
    8000422e:	509c                	lw	a5,32(s1)
    80004230:	37fd                	addiw	a5,a5,-1
    80004232:	0007891b          	sext.w	s2,a5
    80004236:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004238:	50dc                	lw	a5,36(s1)
    8000423a:	efb9                	bnez	a5,80004298 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000423c:	06091663          	bnez	s2,800042a8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004240:	0001e497          	auipc	s1,0x1e
    80004244:	0c848493          	addi	s1,s1,200 # 80022308 <log>
    80004248:	4785                	li	a5,1
    8000424a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	afc080e7          	jalr	-1284(ra) # 80000d4a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004256:	54dc                	lw	a5,44(s1)
    80004258:	06f04763          	bgtz	a5,800042c6 <end_op+0xbc>
    acquire(&log.lock);
    8000425c:	0001e497          	auipc	s1,0x1e
    80004260:	0ac48493          	addi	s1,s1,172 # 80022308 <log>
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a30080e7          	jalr	-1488(ra) # 80000c96 <acquire>
    log.committing = 0;
    8000426e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004272:	8526                	mv	a0,s1
    80004274:	ffffe097          	auipc	ra,0xffffe
    80004278:	1dc080e7          	jalr	476(ra) # 80002450 <wakeup>
    release(&log.lock);
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	acc080e7          	jalr	-1332(ra) # 80000d4a <release>
}
    80004286:	70e2                	ld	ra,56(sp)
    80004288:	7442                	ld	s0,48(sp)
    8000428a:	74a2                	ld	s1,40(sp)
    8000428c:	7902                	ld	s2,32(sp)
    8000428e:	69e2                	ld	s3,24(sp)
    80004290:	6a42                	ld	s4,16(sp)
    80004292:	6aa2                	ld	s5,8(sp)
    80004294:	6121                	addi	sp,sp,64
    80004296:	8082                	ret
    panic("log.committing");
    80004298:	00004517          	auipc	a0,0x4
    8000429c:	3c050513          	addi	a0,a0,960 # 80008658 <syscalls+0x1f0>
    800042a0:	ffffc097          	auipc	ra,0xffffc
    800042a4:	358080e7          	jalr	856(ra) # 800005f8 <panic>
    wakeup(&log);
    800042a8:	0001e497          	auipc	s1,0x1e
    800042ac:	06048493          	addi	s1,s1,96 # 80022308 <log>
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffe097          	auipc	ra,0xffffe
    800042b6:	19e080e7          	jalr	414(ra) # 80002450 <wakeup>
  release(&log.lock);
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	a8e080e7          	jalr	-1394(ra) # 80000d4a <release>
  if(do_commit){
    800042c4:	b7c9                	j	80004286 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c6:	0001ea97          	auipc	s5,0x1e
    800042ca:	072a8a93          	addi	s5,s5,114 # 80022338 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ce:	0001ea17          	auipc	s4,0x1e
    800042d2:	03aa0a13          	addi	s4,s4,58 # 80022308 <log>
    800042d6:	018a2583          	lw	a1,24(s4)
    800042da:	012585bb          	addw	a1,a1,s2
    800042de:	2585                	addiw	a1,a1,1
    800042e0:	028a2503          	lw	a0,40(s4)
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	ce8080e7          	jalr	-792(ra) # 80002fcc <bread>
    800042ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ee:	000aa583          	lw	a1,0(s5)
    800042f2:	028a2503          	lw	a0,40(s4)
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	cd6080e7          	jalr	-810(ra) # 80002fcc <bread>
    800042fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004300:	40000613          	li	a2,1024
    80004304:	05850593          	addi	a1,a0,88
    80004308:	05848513          	addi	a0,s1,88
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	ae6080e7          	jalr	-1306(ra) # 80000df2 <memmove>
    bwrite(to);  // write the log
    80004314:	8526                	mv	a0,s1
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	da8080e7          	jalr	-600(ra) # 800030be <bwrite>
    brelse(from);
    8000431e:	854e                	mv	a0,s3
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	ddc080e7          	jalr	-548(ra) # 800030fc <brelse>
    brelse(to);
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	dd2080e7          	jalr	-558(ra) # 800030fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004332:	2905                	addiw	s2,s2,1
    80004334:	0a91                	addi	s5,s5,4
    80004336:	02ca2783          	lw	a5,44(s4)
    8000433a:	f8f94ee3          	blt	s2,a5,800042d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	c7a080e7          	jalr	-902(ra) # 80003fb8 <write_head>
    install_trans(); // Now install writes to home locations
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	cec080e7          	jalr	-788(ra) # 80004032 <install_trans>
    log.lh.n = 0;
    8000434e:	0001e797          	auipc	a5,0x1e
    80004352:	fe07a323          	sw	zero,-26(a5) # 80022334 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c62080e7          	jalr	-926(ra) # 80003fb8 <write_head>
    8000435e:	bdfd                	j	8000425c <end_op+0x52>

0000000080004360 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000436c:	0001e717          	auipc	a4,0x1e
    80004370:	fc872703          	lw	a4,-56(a4) # 80022334 <log+0x2c>
    80004374:	47f5                	li	a5,29
    80004376:	08e7c063          	blt	a5,a4,800043f6 <log_write+0x96>
    8000437a:	84aa                	mv	s1,a0
    8000437c:	0001e797          	auipc	a5,0x1e
    80004380:	fa87a783          	lw	a5,-88(a5) # 80022324 <log+0x1c>
    80004384:	37fd                	addiw	a5,a5,-1
    80004386:	06f75863          	bge	a4,a5,800043f6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000438a:	0001e797          	auipc	a5,0x1e
    8000438e:	f9e7a783          	lw	a5,-98(a5) # 80022328 <log+0x20>
    80004392:	06f05a63          	blez	a5,80004406 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004396:	0001e917          	auipc	s2,0x1e
    8000439a:	f7290913          	addi	s2,s2,-142 # 80022308 <log>
    8000439e:	854a                	mv	a0,s2
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	8f6080e7          	jalr	-1802(ra) # 80000c96 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	02c92603          	lw	a2,44(s2)
    800043ac:	06c05563          	blez	a2,80004416 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043b0:	44cc                	lw	a1,12(s1)
    800043b2:	0001e717          	auipc	a4,0x1e
    800043b6:	f8670713          	addi	a4,a4,-122 # 80022338 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043bc:	4314                	lw	a3,0(a4)
    800043be:	04b68d63          	beq	a3,a1,80004418 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	2785                	addiw	a5,a5,1
    800043c4:	0711                	addi	a4,a4,4
    800043c6:	fec79be3          	bne	a5,a2,800043bc <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ca:	0621                	addi	a2,a2,8
    800043cc:	060a                	slli	a2,a2,0x2
    800043ce:	0001e797          	auipc	a5,0x1e
    800043d2:	f3a78793          	addi	a5,a5,-198 # 80022308 <log>
    800043d6:	963e                	add	a2,a2,a5
    800043d8:	44dc                	lw	a5,12(s1)
    800043da:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	dbc080e7          	jalr	-580(ra) # 8000319a <bpin>
    log.lh.n++;
    800043e6:	0001e717          	auipc	a4,0x1e
    800043ea:	f2270713          	addi	a4,a4,-222 # 80022308 <log>
    800043ee:	575c                	lw	a5,44(a4)
    800043f0:	2785                	addiw	a5,a5,1
    800043f2:	d75c                	sw	a5,44(a4)
    800043f4:	a83d                	j	80004432 <log_write+0xd2>
    panic("too big a transaction");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	27250513          	addi	a0,a0,626 # 80008668 <syscalls+0x200>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	1fa080e7          	jalr	506(ra) # 800005f8 <panic>
    panic("log_write outside of trans");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	27a50513          	addi	a0,a0,634 # 80008680 <syscalls+0x218>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	1ea080e7          	jalr	490(ra) # 800005f8 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004416:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004418:	00878713          	addi	a4,a5,8
    8000441c:	00271693          	slli	a3,a4,0x2
    80004420:	0001e717          	auipc	a4,0x1e
    80004424:	ee870713          	addi	a4,a4,-280 # 80022308 <log>
    80004428:	9736                	add	a4,a4,a3
    8000442a:	44d4                	lw	a3,12(s1)
    8000442c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442e:	faf607e3          	beq	a2,a5,800043dc <log_write+0x7c>
  }
  release(&log.lock);
    80004432:	0001e517          	auipc	a0,0x1e
    80004436:	ed650513          	addi	a0,a0,-298 # 80022308 <log>
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	910080e7          	jalr	-1776(ra) # 80000d4a <release>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
    8000445a:	84aa                	mv	s1,a0
    8000445c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445e:	00004597          	auipc	a1,0x4
    80004462:	24258593          	addi	a1,a1,578 # 800086a0 <syscalls+0x238>
    80004466:	0521                	addi	a0,a0,8
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	79e080e7          	jalr	1950(ra) # 80000c06 <initlock>
  lk->name = name;
    80004470:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004474:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004478:	0204a423          	sw	zero,40(s1)
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret

0000000080004488 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004496:	00850913          	addi	s2,a0,8
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	7fa080e7          	jalr	2042(ra) # 80000c96 <acquire>
  while (lk->locked) {
    800044a4:	409c                	lw	a5,0(s1)
    800044a6:	cb89                	beqz	a5,800044b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a8:	85ca                	mv	a1,s2
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffe097          	auipc	ra,0xffffe
    800044b0:	e1e080e7          	jalr	-482(ra) # 800022ca <sleep>
  while (lk->locked) {
    800044b4:	409c                	lw	a5,0(s1)
    800044b6:	fbed                	bnez	a5,800044a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b8:	4785                	li	a5,1
    800044ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	5a8080e7          	jalr	1448(ra) # 80001a64 <myproc>
    800044c4:	5d1c                	lw	a5,56(a0)
    800044c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	880080e7          	jalr	-1920(ra) # 80000d4a <release>
}
    800044d2:	60e2                	ld	ra,24(sp)
    800044d4:	6442                	ld	s0,16(sp)
    800044d6:	64a2                	ld	s1,8(sp)
    800044d8:	6902                	ld	s2,0(sp)
    800044da:	6105                	addi	sp,sp,32
    800044dc:	8082                	ret

00000000800044de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
    800044ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ec:	00850913          	addi	s2,a0,8
    800044f0:	854a                	mv	a0,s2
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	7a4080e7          	jalr	1956(ra) # 80000c96 <acquire>
  lk->locked = 0;
    800044fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffe097          	auipc	ra,0xffffe
    80004508:	f4c080e7          	jalr	-180(ra) # 80002450 <wakeup>
  release(&lk->lk);
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	83c080e7          	jalr	-1988(ra) # 80000d4a <release>
}
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6902                	ld	s2,0(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004522:	7179                	addi	sp,sp,-48
    80004524:	f406                	sd	ra,40(sp)
    80004526:	f022                	sd	s0,32(sp)
    80004528:	ec26                	sd	s1,24(sp)
    8000452a:	e84a                	sd	s2,16(sp)
    8000452c:	e44e                	sd	s3,8(sp)
    8000452e:	1800                	addi	s0,sp,48
    80004530:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004532:	00850913          	addi	s2,a0,8
    80004536:	854a                	mv	a0,s2
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	75e080e7          	jalr	1886(ra) # 80000c96 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	409c                	lw	a5,0(s1)
    80004542:	ef99                	bnez	a5,80004560 <holdingsleep+0x3e>
    80004544:	4481                	li	s1,0
  release(&lk->lk);
    80004546:	854a                	mv	a0,s2
    80004548:	ffffd097          	auipc	ra,0xffffd
    8000454c:	802080e7          	jalr	-2046(ra) # 80000d4a <release>
  return r;
}
    80004550:	8526                	mv	a0,s1
    80004552:	70a2                	ld	ra,40(sp)
    80004554:	7402                	ld	s0,32(sp)
    80004556:	64e2                	ld	s1,24(sp)
    80004558:	6942                	ld	s2,16(sp)
    8000455a:	69a2                	ld	s3,8(sp)
    8000455c:	6145                	addi	sp,sp,48
    8000455e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004560:	0284a983          	lw	s3,40(s1)
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	500080e7          	jalr	1280(ra) # 80001a64 <myproc>
    8000456c:	5d04                	lw	s1,56(a0)
    8000456e:	413484b3          	sub	s1,s1,s3
    80004572:	0014b493          	seqz	s1,s1
    80004576:	bfc1                	j	80004546 <holdingsleep+0x24>

0000000080004578 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004578:	1141                	addi	sp,sp,-16
    8000457a:	e406                	sd	ra,8(sp)
    8000457c:	e022                	sd	s0,0(sp)
    8000457e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004580:	00004597          	auipc	a1,0x4
    80004584:	13058593          	addi	a1,a1,304 # 800086b0 <syscalls+0x248>
    80004588:	0001e517          	auipc	a0,0x1e
    8000458c:	ec850513          	addi	a0,a0,-312 # 80022450 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	676080e7          	jalr	1654(ra) # 80000c06 <initlock>
}
    80004598:	60a2                	ld	ra,8(sp)
    8000459a:	6402                	ld	s0,0(sp)
    8000459c:	0141                	addi	sp,sp,16
    8000459e:	8082                	ret

00000000800045a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045aa:	0001e517          	auipc	a0,0x1e
    800045ae:	ea650513          	addi	a0,a0,-346 # 80022450 <ftable>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	6e4080e7          	jalr	1764(ra) # 80000c96 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ba:	0001e497          	auipc	s1,0x1e
    800045be:	eae48493          	addi	s1,s1,-338 # 80022468 <ftable+0x18>
    800045c2:	0001f717          	auipc	a4,0x1f
    800045c6:	e4670713          	addi	a4,a4,-442 # 80023408 <ftable+0xfb8>
    if(f->ref == 0){
    800045ca:	40dc                	lw	a5,4(s1)
    800045cc:	cf99                	beqz	a5,800045ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ce:	02848493          	addi	s1,s1,40
    800045d2:	fee49ce3          	bne	s1,a4,800045ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d6:	0001e517          	auipc	a0,0x1e
    800045da:	e7a50513          	addi	a0,a0,-390 # 80022450 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	76c080e7          	jalr	1900(ra) # 80000d4a <release>
  return 0;
    800045e6:	4481                	li	s1,0
    800045e8:	a819                	j	800045fe <filealloc+0x5e>
      f->ref = 1;
    800045ea:	4785                	li	a5,1
    800045ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ee:	0001e517          	auipc	a0,0x1e
    800045f2:	e6250513          	addi	a0,a0,-414 # 80022450 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	754080e7          	jalr	1876(ra) # 80000d4a <release>
}
    800045fe:	8526                	mv	a0,s1
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	1000                	addi	s0,sp,32
    80004614:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004616:	0001e517          	auipc	a0,0x1e
    8000461a:	e3a50513          	addi	a0,a0,-454 # 80022450 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	678080e7          	jalr	1656(ra) # 80000c96 <acquire>
  if(f->ref < 1)
    80004626:	40dc                	lw	a5,4(s1)
    80004628:	02f05263          	blez	a5,8000464c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462c:	2785                	addiw	a5,a5,1
    8000462e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004630:	0001e517          	auipc	a0,0x1e
    80004634:	e2050513          	addi	a0,a0,-480 # 80022450 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	712080e7          	jalr	1810(ra) # 80000d4a <release>
  return f;
}
    80004640:	8526                	mv	a0,s1
    80004642:	60e2                	ld	ra,24(sp)
    80004644:	6442                	ld	s0,16(sp)
    80004646:	64a2                	ld	s1,8(sp)
    80004648:	6105                	addi	sp,sp,32
    8000464a:	8082                	ret
    panic("filedup");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	06c50513          	addi	a0,a0,108 # 800086b8 <syscalls+0x250>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	fa4080e7          	jalr	-92(ra) # 800005f8 <panic>

000000008000465c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	0080                	addi	s0,sp,64
    8000466e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004670:	0001e517          	auipc	a0,0x1e
    80004674:	de050513          	addi	a0,a0,-544 # 80022450 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	61e080e7          	jalr	1566(ra) # 80000c96 <acquire>
  if(f->ref < 1)
    80004680:	40dc                	lw	a5,4(s1)
    80004682:	06f05163          	blez	a5,800046e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	0007871b          	sext.w	a4,a5
    8000468c:	c0dc                	sw	a5,4(s1)
    8000468e:	06e04363          	bgtz	a4,800046f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004692:	0004a903          	lw	s2,0(s1)
    80004696:	0094ca83          	lbu	s5,9(s1)
    8000469a:	0104ba03          	ld	s4,16(s1)
    8000469e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046aa:	0001e517          	auipc	a0,0x1e
    800046ae:	da650513          	addi	a0,a0,-602 # 80022450 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	698080e7          	jalr	1688(ra) # 80000d4a <release>

  if(ff.type == FD_PIPE){
    800046ba:	4785                	li	a5,1
    800046bc:	04f90d63          	beq	s2,a5,80004716 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046c0:	3979                	addiw	s2,s2,-2
    800046c2:	4785                	li	a5,1
    800046c4:	0527e063          	bltu	a5,s2,80004704 <fileclose+0xa8>
    begin_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	ac2080e7          	jalr	-1342(ra) # 8000418a <begin_op>
    iput(ff.ip);
    800046d0:	854e                	mv	a0,s3
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	2b6080e7          	jalr	694(ra) # 80003988 <iput>
    end_op();
    800046da:	00000097          	auipc	ra,0x0
    800046de:	b30080e7          	jalr	-1232(ra) # 8000420a <end_op>
    800046e2:	a00d                	j	80004704 <fileclose+0xa8>
    panic("fileclose");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	fdc50513          	addi	a0,a0,-36 # 800086c0 <syscalls+0x258>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	f0c080e7          	jalr	-244(ra) # 800005f8 <panic>
    release(&ftable.lock);
    800046f4:	0001e517          	auipc	a0,0x1e
    800046f8:	d5c50513          	addi	a0,a0,-676 # 80022450 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	64e080e7          	jalr	1614(ra) # 80000d4a <release>
  }
}
    80004704:	70e2                	ld	ra,56(sp)
    80004706:	7442                	ld	s0,48(sp)
    80004708:	74a2                	ld	s1,40(sp)
    8000470a:	7902                	ld	s2,32(sp)
    8000470c:	69e2                	ld	s3,24(sp)
    8000470e:	6a42                	ld	s4,16(sp)
    80004710:	6aa2                	ld	s5,8(sp)
    80004712:	6121                	addi	sp,sp,64
    80004714:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004716:	85d6                	mv	a1,s5
    80004718:	8552                	mv	a0,s4
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	372080e7          	jalr	882(ra) # 80004a8c <pipeclose>
    80004722:	b7cd                	j	80004704 <fileclose+0xa8>

0000000080004724 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004724:	715d                	addi	sp,sp,-80
    80004726:	e486                	sd	ra,72(sp)
    80004728:	e0a2                	sd	s0,64(sp)
    8000472a:	fc26                	sd	s1,56(sp)
    8000472c:	f84a                	sd	s2,48(sp)
    8000472e:	f44e                	sd	s3,40(sp)
    80004730:	0880                	addi	s0,sp,80
    80004732:	84aa                	mv	s1,a0
    80004734:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004736:	ffffd097          	auipc	ra,0xffffd
    8000473a:	32e080e7          	jalr	814(ra) # 80001a64 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473e:	409c                	lw	a5,0(s1)
    80004740:	37f9                	addiw	a5,a5,-2
    80004742:	4705                	li	a4,1
    80004744:	04f76763          	bltu	a4,a5,80004792 <filestat+0x6e>
    80004748:	892a                	mv	s2,a0
    ilock(f->ip);
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	082080e7          	jalr	130(ra) # 800037ce <ilock>
    stati(f->ip, &st);
    80004754:	fb840593          	addi	a1,s0,-72
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	2fe080e7          	jalr	766(ra) # 80003a58 <stati>
    iunlock(f->ip);
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	12c080e7          	jalr	300(ra) # 80003890 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476c:	46e1                	li	a3,24
    8000476e:	fb840613          	addi	a2,s0,-72
    80004772:	85ce                	mv	a1,s3
    80004774:	05093503          	ld	a0,80(s2)
    80004778:	ffffd097          	auipc	ra,0xffffd
    8000477c:	fe0080e7          	jalr	-32(ra) # 80001758 <copyout>
    80004780:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004784:	60a6                	ld	ra,72(sp)
    80004786:	6406                	ld	s0,64(sp)
    80004788:	74e2                	ld	s1,56(sp)
    8000478a:	7942                	ld	s2,48(sp)
    8000478c:	79a2                	ld	s3,40(sp)
    8000478e:	6161                	addi	sp,sp,80
    80004790:	8082                	ret
  return -1;
    80004792:	557d                	li	a0,-1
    80004794:	bfc5                	j	80004784 <filestat+0x60>

0000000080004796 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004796:	7179                	addi	sp,sp,-48
    80004798:	f406                	sd	ra,40(sp)
    8000479a:	f022                	sd	s0,32(sp)
    8000479c:	ec26                	sd	s1,24(sp)
    8000479e:	e84a                	sd	s2,16(sp)
    800047a0:	e44e                	sd	s3,8(sp)
    800047a2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a4:	00854783          	lbu	a5,8(a0)
    800047a8:	c3d5                	beqz	a5,8000484c <fileread+0xb6>
    800047aa:	84aa                	mv	s1,a0
    800047ac:	89ae                	mv	s3,a1
    800047ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	04e78963          	beq	a5,a4,80004806 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	04e78d63          	beq	a5,a4,80004814 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	06e79e63          	bne	a5,a4,8000483c <fileread+0xa6>
    ilock(f->ip);
    800047c4:	6d08                	ld	a0,24(a0)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	008080e7          	jalr	8(ra) # 800037ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ce:	874a                	mv	a4,s2
    800047d0:	5094                	lw	a3,32(s1)
    800047d2:	864e                	mv	a2,s3
    800047d4:	4585                	li	a1,1
    800047d6:	6c88                	ld	a0,24(s1)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	2aa080e7          	jalr	682(ra) # 80003a82 <readi>
    800047e0:	892a                	mv	s2,a0
    800047e2:	00a05563          	blez	a0,800047ec <fileread+0x56>
      f->off += r;
    800047e6:	509c                	lw	a5,32(s1)
    800047e8:	9fa9                	addw	a5,a5,a0
    800047ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ec:	6c88                	ld	a0,24(s1)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	0a2080e7          	jalr	162(ra) # 80003890 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f6:	854a                	mv	a0,s2
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6145                	addi	sp,sp,48
    80004804:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004806:	6908                	ld	a0,16(a0)
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	418080e7          	jalr	1048(ra) # 80004c20 <piperead>
    80004810:	892a                	mv	s2,a0
    80004812:	b7d5                	j	800047f6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004814:	02451783          	lh	a5,36(a0)
    80004818:	03079693          	slli	a3,a5,0x30
    8000481c:	92c1                	srli	a3,a3,0x30
    8000481e:	4725                	li	a4,9
    80004820:	02d76863          	bltu	a4,a3,80004850 <fileread+0xba>
    80004824:	0792                	slli	a5,a5,0x4
    80004826:	0001e717          	auipc	a4,0x1e
    8000482a:	b8a70713          	addi	a4,a4,-1142 # 800223b0 <devsw>
    8000482e:	97ba                	add	a5,a5,a4
    80004830:	639c                	ld	a5,0(a5)
    80004832:	c38d                	beqz	a5,80004854 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004834:	4505                	li	a0,1
    80004836:	9782                	jalr	a5
    80004838:	892a                	mv	s2,a0
    8000483a:	bf75                	j	800047f6 <fileread+0x60>
    panic("fileread");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	e9450513          	addi	a0,a0,-364 # 800086d0 <syscalls+0x268>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	db4080e7          	jalr	-588(ra) # 800005f8 <panic>
    return -1;
    8000484c:	597d                	li	s2,-1
    8000484e:	b765                	j	800047f6 <fileread+0x60>
      return -1;
    80004850:	597d                	li	s2,-1
    80004852:	b755                	j	800047f6 <fileread+0x60>
    80004854:	597d                	li	s2,-1
    80004856:	b745                	j	800047f6 <fileread+0x60>

0000000080004858 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004858:	00954783          	lbu	a5,9(a0)
    8000485c:	14078563          	beqz	a5,800049a6 <filewrite+0x14e>
{
    80004860:	715d                	addi	sp,sp,-80
    80004862:	e486                	sd	ra,72(sp)
    80004864:	e0a2                	sd	s0,64(sp)
    80004866:	fc26                	sd	s1,56(sp)
    80004868:	f84a                	sd	s2,48(sp)
    8000486a:	f44e                	sd	s3,40(sp)
    8000486c:	f052                	sd	s4,32(sp)
    8000486e:	ec56                	sd	s5,24(sp)
    80004870:	e85a                	sd	s6,16(sp)
    80004872:	e45e                	sd	s7,8(sp)
    80004874:	e062                	sd	s8,0(sp)
    80004876:	0880                	addi	s0,sp,80
    80004878:	892a                	mv	s2,a0
    8000487a:	8aae                	mv	s5,a1
    8000487c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487e:	411c                	lw	a5,0(a0)
    80004880:	4705                	li	a4,1
    80004882:	02e78263          	beq	a5,a4,800048a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004886:	470d                	li	a4,3
    80004888:	02e78563          	beq	a5,a4,800048b2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488c:	4709                	li	a4,2
    8000488e:	10e79463          	bne	a5,a4,80004996 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004892:	0ec05e63          	blez	a2,8000498e <filewrite+0x136>
    int i = 0;
    80004896:	4981                	li	s3,0
    80004898:	6b05                	lui	s6,0x1
    8000489a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000489e:	6b85                	lui	s7,0x1
    800048a0:	c00b8b9b          	addiw	s7,s7,-1024
    800048a4:	a851                	j	80004938 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048a6:	6908                	ld	a0,16(a0)
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	254080e7          	jalr	596(ra) # 80004afc <pipewrite>
    800048b0:	a85d                	j	80004966 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b2:	02451783          	lh	a5,36(a0)
    800048b6:	03079693          	slli	a3,a5,0x30
    800048ba:	92c1                	srli	a3,a3,0x30
    800048bc:	4725                	li	a4,9
    800048be:	0ed76663          	bltu	a4,a3,800049aa <filewrite+0x152>
    800048c2:	0792                	slli	a5,a5,0x4
    800048c4:	0001e717          	auipc	a4,0x1e
    800048c8:	aec70713          	addi	a4,a4,-1300 # 800223b0 <devsw>
    800048cc:	97ba                	add	a5,a5,a4
    800048ce:	679c                	ld	a5,8(a5)
    800048d0:	cff9                	beqz	a5,800049ae <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048d2:	4505                	li	a0,1
    800048d4:	9782                	jalr	a5
    800048d6:	a841                	j	80004966 <filewrite+0x10e>
    800048d8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	8ae080e7          	jalr	-1874(ra) # 8000418a <begin_op>
      ilock(f->ip);
    800048e4:	01893503          	ld	a0,24(s2)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	ee6080e7          	jalr	-282(ra) # 800037ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f0:	8762                	mv	a4,s8
    800048f2:	02092683          	lw	a3,32(s2)
    800048f6:	01598633          	add	a2,s3,s5
    800048fa:	4585                	li	a1,1
    800048fc:	01893503          	ld	a0,24(s2)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	278080e7          	jalr	632(ra) # 80003b78 <writei>
    80004908:	84aa                	mv	s1,a0
    8000490a:	02a05f63          	blez	a0,80004948 <filewrite+0xf0>
        f->off += r;
    8000490e:	02092783          	lw	a5,32(s2)
    80004912:	9fa9                	addw	a5,a5,a0
    80004914:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004918:	01893503          	ld	a0,24(s2)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	f74080e7          	jalr	-140(ra) # 80003890 <iunlock>
      end_op();
    80004924:	00000097          	auipc	ra,0x0
    80004928:	8e6080e7          	jalr	-1818(ra) # 8000420a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000492c:	049c1963          	bne	s8,s1,8000497e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004930:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004934:	0349d663          	bge	s3,s4,80004960 <filewrite+0x108>
      int n1 = n - i;
    80004938:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000493c:	84be                	mv	s1,a5
    8000493e:	2781                	sext.w	a5,a5
    80004940:	f8fb5ce3          	bge	s6,a5,800048d8 <filewrite+0x80>
    80004944:	84de                	mv	s1,s7
    80004946:	bf49                	j	800048d8 <filewrite+0x80>
      iunlock(f->ip);
    80004948:	01893503          	ld	a0,24(s2)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	f44080e7          	jalr	-188(ra) # 80003890 <iunlock>
      end_op();
    80004954:	00000097          	auipc	ra,0x0
    80004958:	8b6080e7          	jalr	-1866(ra) # 8000420a <end_op>
      if(r < 0)
    8000495c:	fc04d8e3          	bgez	s1,8000492c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004960:	8552                	mv	a0,s4
    80004962:	033a1863          	bne	s4,s3,80004992 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004966:	60a6                	ld	ra,72(sp)
    80004968:	6406                	ld	s0,64(sp)
    8000496a:	74e2                	ld	s1,56(sp)
    8000496c:	7942                	ld	s2,48(sp)
    8000496e:	79a2                	ld	s3,40(sp)
    80004970:	7a02                	ld	s4,32(sp)
    80004972:	6ae2                	ld	s5,24(sp)
    80004974:	6b42                	ld	s6,16(sp)
    80004976:	6ba2                	ld	s7,8(sp)
    80004978:	6c02                	ld	s8,0(sp)
    8000497a:	6161                	addi	sp,sp,80
    8000497c:	8082                	ret
        panic("short filewrite");
    8000497e:	00004517          	auipc	a0,0x4
    80004982:	d6250513          	addi	a0,a0,-670 # 800086e0 <syscalls+0x278>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	c72080e7          	jalr	-910(ra) # 800005f8 <panic>
    int i = 0;
    8000498e:	4981                	li	s3,0
    80004990:	bfc1                	j	80004960 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004992:	557d                	li	a0,-1
    80004994:	bfc9                	j	80004966 <filewrite+0x10e>
    panic("filewrite");
    80004996:	00004517          	auipc	a0,0x4
    8000499a:	d5a50513          	addi	a0,a0,-678 # 800086f0 <syscalls+0x288>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	c5a080e7          	jalr	-934(ra) # 800005f8 <panic>
    return -1;
    800049a6:	557d                	li	a0,-1
}
    800049a8:	8082                	ret
      return -1;
    800049aa:	557d                	li	a0,-1
    800049ac:	bf6d                	j	80004966 <filewrite+0x10e>
    800049ae:	557d                	li	a0,-1
    800049b0:	bf5d                	j	80004966 <filewrite+0x10e>

00000000800049b2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049b2:	7179                	addi	sp,sp,-48
    800049b4:	f406                	sd	ra,40(sp)
    800049b6:	f022                	sd	s0,32(sp)
    800049b8:	ec26                	sd	s1,24(sp)
    800049ba:	e84a                	sd	s2,16(sp)
    800049bc:	e44e                	sd	s3,8(sp)
    800049be:	e052                	sd	s4,0(sp)
    800049c0:	1800                	addi	s0,sp,48
    800049c2:	84aa                	mv	s1,a0
    800049c4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049c6:	0005b023          	sd	zero,0(a1)
    800049ca:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	bd2080e7          	jalr	-1070(ra) # 800045a0 <filealloc>
    800049d6:	e088                	sd	a0,0(s1)
    800049d8:	c551                	beqz	a0,80004a64 <pipealloc+0xb2>
    800049da:	00000097          	auipc	ra,0x0
    800049de:	bc6080e7          	jalr	-1082(ra) # 800045a0 <filealloc>
    800049e2:	00aa3023          	sd	a0,0(s4)
    800049e6:	c92d                	beqz	a0,80004a58 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	1be080e7          	jalr	446(ra) # 80000ba6 <kalloc>
    800049f0:	892a                	mv	s2,a0
    800049f2:	c125                	beqz	a0,80004a52 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049f4:	4985                	li	s3,1
    800049f6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049fa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049fe:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a02:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a06:	00004597          	auipc	a1,0x4
    80004a0a:	cfa58593          	addi	a1,a1,-774 # 80008700 <syscalls+0x298>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	1f8080e7          	jalr	504(ra) # 80000c06 <initlock>
  (*f0)->type = FD_PIPE;
    80004a16:	609c                	ld	a5,0(s1)
    80004a18:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a1c:	609c                	ld	a5,0(s1)
    80004a1e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a22:	609c                	ld	a5,0(s1)
    80004a24:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a28:	609c                	ld	a5,0(s1)
    80004a2a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a2e:	000a3783          	ld	a5,0(s4)
    80004a32:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a36:	000a3783          	ld	a5,0(s4)
    80004a3a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a3e:	000a3783          	ld	a5,0(s4)
    80004a42:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a46:	000a3783          	ld	a5,0(s4)
    80004a4a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a4e:	4501                	li	a0,0
    80004a50:	a025                	j	80004a78 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a52:	6088                	ld	a0,0(s1)
    80004a54:	e501                	bnez	a0,80004a5c <pipealloc+0xaa>
    80004a56:	a039                	j	80004a64 <pipealloc+0xb2>
    80004a58:	6088                	ld	a0,0(s1)
    80004a5a:	c51d                	beqz	a0,80004a88 <pipealloc+0xd6>
    fileclose(*f0);
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	c00080e7          	jalr	-1024(ra) # 8000465c <fileclose>
  if(*f1)
    80004a64:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a68:	557d                	li	a0,-1
  if(*f1)
    80004a6a:	c799                	beqz	a5,80004a78 <pipealloc+0xc6>
    fileclose(*f1);
    80004a6c:	853e                	mv	a0,a5
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	bee080e7          	jalr	-1042(ra) # 8000465c <fileclose>
  return -1;
    80004a76:	557d                	li	a0,-1
}
    80004a78:	70a2                	ld	ra,40(sp)
    80004a7a:	7402                	ld	s0,32(sp)
    80004a7c:	64e2                	ld	s1,24(sp)
    80004a7e:	6942                	ld	s2,16(sp)
    80004a80:	69a2                	ld	s3,8(sp)
    80004a82:	6a02                	ld	s4,0(sp)
    80004a84:	6145                	addi	sp,sp,48
    80004a86:	8082                	ret
  return -1;
    80004a88:	557d                	li	a0,-1
    80004a8a:	b7fd                	j	80004a78 <pipealloc+0xc6>

0000000080004a8c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a8c:	1101                	addi	sp,sp,-32
    80004a8e:	ec06                	sd	ra,24(sp)
    80004a90:	e822                	sd	s0,16(sp)
    80004a92:	e426                	sd	s1,8(sp)
    80004a94:	e04a                	sd	s2,0(sp)
    80004a96:	1000                	addi	s0,sp,32
    80004a98:	84aa                	mv	s1,a0
    80004a9a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	1fa080e7          	jalr	506(ra) # 80000c96 <acquire>
  if(writable){
    80004aa4:	02090d63          	beqz	s2,80004ade <pipeclose+0x52>
    pi->writeopen = 0;
    80004aa8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aac:	21848513          	addi	a0,s1,536
    80004ab0:	ffffe097          	auipc	ra,0xffffe
    80004ab4:	9a0080e7          	jalr	-1632(ra) # 80002450 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ab8:	2204b783          	ld	a5,544(s1)
    80004abc:	eb95                	bnez	a5,80004af0 <pipeclose+0x64>
    release(&pi->lock);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	28a080e7          	jalr	650(ra) # 80000d4a <release>
    kfree((char*)pi);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	fe0080e7          	jalr	-32(ra) # 80000aaa <kfree>
  } else
    release(&pi->lock);
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	64a2                	ld	s1,8(sp)
    80004ad8:	6902                	ld	s2,0(sp)
    80004ada:	6105                	addi	sp,sp,32
    80004adc:	8082                	ret
    pi->readopen = 0;
    80004ade:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ae2:	21c48513          	addi	a0,s1,540
    80004ae6:	ffffe097          	auipc	ra,0xffffe
    80004aea:	96a080e7          	jalr	-1686(ra) # 80002450 <wakeup>
    80004aee:	b7e9                	j	80004ab8 <pipeclose+0x2c>
    release(&pi->lock);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	258080e7          	jalr	600(ra) # 80000d4a <release>
}
    80004afa:	bfe1                	j	80004ad2 <pipeclose+0x46>

0000000080004afc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004afc:	7119                	addi	sp,sp,-128
    80004afe:	fc86                	sd	ra,120(sp)
    80004b00:	f8a2                	sd	s0,112(sp)
    80004b02:	f4a6                	sd	s1,104(sp)
    80004b04:	f0ca                	sd	s2,96(sp)
    80004b06:	ecce                	sd	s3,88(sp)
    80004b08:	e8d2                	sd	s4,80(sp)
    80004b0a:	e4d6                	sd	s5,72(sp)
    80004b0c:	e0da                	sd	s6,64(sp)
    80004b0e:	fc5e                	sd	s7,56(sp)
    80004b10:	f862                	sd	s8,48(sp)
    80004b12:	f466                	sd	s9,40(sp)
    80004b14:	f06a                	sd	s10,32(sp)
    80004b16:	ec6e                	sd	s11,24(sp)
    80004b18:	0100                	addi	s0,sp,128
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	8cae                	mv	s9,a1
    80004b1e:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	f44080e7          	jalr	-188(ra) # 80001a64 <myproc>
    80004b28:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16a080e7          	jalr	362(ra) # 80000c96 <acquire>
  for(i = 0; i < n; i++){
    80004b34:	0d605963          	blez	s6,80004c06 <pipewrite+0x10a>
    80004b38:	89a6                	mv	s3,s1
    80004b3a:	3b7d                	addiw	s6,s6,-1
    80004b3c:	1b02                	slli	s6,s6,0x20
    80004b3e:	020b5b13          	srli	s6,s6,0x20
    80004b42:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b44:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b48:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b4c:	5dfd                	li	s11,-1
    80004b4e:	000b8d1b          	sext.w	s10,s7
    80004b52:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b54:	2184a783          	lw	a5,536(s1)
    80004b58:	21c4a703          	lw	a4,540(s1)
    80004b5c:	2007879b          	addiw	a5,a5,512
    80004b60:	02f71b63          	bne	a4,a5,80004b96 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b64:	2204a783          	lw	a5,544(s1)
    80004b68:	cbad                	beqz	a5,80004bda <pipewrite+0xde>
    80004b6a:	03092783          	lw	a5,48(s2)
    80004b6e:	e7b5                	bnez	a5,80004bda <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b70:	8556                	mv	a0,s5
    80004b72:	ffffe097          	auipc	ra,0xffffe
    80004b76:	8de080e7          	jalr	-1826(ra) # 80002450 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b7a:	85ce                	mv	a1,s3
    80004b7c:	8552                	mv	a0,s4
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	74c080e7          	jalr	1868(ra) # 800022ca <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b86:	2184a783          	lw	a5,536(s1)
    80004b8a:	21c4a703          	lw	a4,540(s1)
    80004b8e:	2007879b          	addiw	a5,a5,512
    80004b92:	fcf709e3          	beq	a4,a5,80004b64 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b96:	4685                	li	a3,1
    80004b98:	019b8633          	add	a2,s7,s9
    80004b9c:	f8f40593          	addi	a1,s0,-113
    80004ba0:	05093503          	ld	a0,80(s2)
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	c40080e7          	jalr	-960(ra) # 800017e4 <copyin>
    80004bac:	05b50e63          	beq	a0,s11,80004c08 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bb0:	21c4a783          	lw	a5,540(s1)
    80004bb4:	0017871b          	addiw	a4,a5,1
    80004bb8:	20e4ae23          	sw	a4,540(s1)
    80004bbc:	1ff7f793          	andi	a5,a5,511
    80004bc0:	97a6                	add	a5,a5,s1
    80004bc2:	f8f44703          	lbu	a4,-113(s0)
    80004bc6:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bca:	001d0c1b          	addiw	s8,s10,1
    80004bce:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004bd2:	036b8b63          	beq	s7,s6,80004c08 <pipewrite+0x10c>
    80004bd6:	8bbe                	mv	s7,a5
    80004bd8:	bf9d                	j	80004b4e <pipewrite+0x52>
        release(&pi->lock);
    80004bda:	8526                	mv	a0,s1
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	16e080e7          	jalr	366(ra) # 80000d4a <release>
        return -1;
    80004be4:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004be6:	8562                	mv	a0,s8
    80004be8:	70e6                	ld	ra,120(sp)
    80004bea:	7446                	ld	s0,112(sp)
    80004bec:	74a6                	ld	s1,104(sp)
    80004bee:	7906                	ld	s2,96(sp)
    80004bf0:	69e6                	ld	s3,88(sp)
    80004bf2:	6a46                	ld	s4,80(sp)
    80004bf4:	6aa6                	ld	s5,72(sp)
    80004bf6:	6b06                	ld	s6,64(sp)
    80004bf8:	7be2                	ld	s7,56(sp)
    80004bfa:	7c42                	ld	s8,48(sp)
    80004bfc:	7ca2                	ld	s9,40(sp)
    80004bfe:	7d02                	ld	s10,32(sp)
    80004c00:	6de2                	ld	s11,24(sp)
    80004c02:	6109                	addi	sp,sp,128
    80004c04:	8082                	ret
  for(i = 0; i < n; i++){
    80004c06:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c08:	21848513          	addi	a0,s1,536
    80004c0c:	ffffe097          	auipc	ra,0xffffe
    80004c10:	844080e7          	jalr	-1980(ra) # 80002450 <wakeup>
  release(&pi->lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	134080e7          	jalr	308(ra) # 80000d4a <release>
  return i;
    80004c1e:	b7e1                	j	80004be6 <pipewrite+0xea>

0000000080004c20 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c20:	715d                	addi	sp,sp,-80
    80004c22:	e486                	sd	ra,72(sp)
    80004c24:	e0a2                	sd	s0,64(sp)
    80004c26:	fc26                	sd	s1,56(sp)
    80004c28:	f84a                	sd	s2,48(sp)
    80004c2a:	f44e                	sd	s3,40(sp)
    80004c2c:	f052                	sd	s4,32(sp)
    80004c2e:	ec56                	sd	s5,24(sp)
    80004c30:	e85a                	sd	s6,16(sp)
    80004c32:	0880                	addi	s0,sp,80
    80004c34:	84aa                	mv	s1,a0
    80004c36:	892e                	mv	s2,a1
    80004c38:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	e2a080e7          	jalr	-470(ra) # 80001a64 <myproc>
    80004c42:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c44:	8b26                	mv	s6,s1
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	04e080e7          	jalr	78(ra) # 80000c96 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c50:	2184a703          	lw	a4,536(s1)
    80004c54:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c58:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c5c:	02f71463          	bne	a4,a5,80004c84 <piperead+0x64>
    80004c60:	2244a783          	lw	a5,548(s1)
    80004c64:	c385                	beqz	a5,80004c84 <piperead+0x64>
    if(pr->killed){
    80004c66:	030a2783          	lw	a5,48(s4)
    80004c6a:	ebc1                	bnez	a5,80004cfa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c6c:	85da                	mv	a1,s6
    80004c6e:	854e                	mv	a0,s3
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	65a080e7          	jalr	1626(ra) # 800022ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c78:	2184a703          	lw	a4,536(s1)
    80004c7c:	21c4a783          	lw	a5,540(s1)
    80004c80:	fef700e3          	beq	a4,a5,80004c60 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c84:	09505263          	blez	s5,80004d08 <piperead+0xe8>
    80004c88:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c8c:	2184a783          	lw	a5,536(s1)
    80004c90:	21c4a703          	lw	a4,540(s1)
    80004c94:	02f70d63          	beq	a4,a5,80004cce <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c98:	0017871b          	addiw	a4,a5,1
    80004c9c:	20e4ac23          	sw	a4,536(s1)
    80004ca0:	1ff7f793          	andi	a5,a5,511
    80004ca4:	97a6                	add	a5,a5,s1
    80004ca6:	0187c783          	lbu	a5,24(a5)
    80004caa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cae:	4685                	li	a3,1
    80004cb0:	fbf40613          	addi	a2,s0,-65
    80004cb4:	85ca                	mv	a1,s2
    80004cb6:	050a3503          	ld	a0,80(s4)
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	a9e080e7          	jalr	-1378(ra) # 80001758 <copyout>
    80004cc2:	01650663          	beq	a0,s6,80004cce <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc6:	2985                	addiw	s3,s3,1
    80004cc8:	0905                	addi	s2,s2,1
    80004cca:	fd3a91e3          	bne	s5,s3,80004c8c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cce:	21c48513          	addi	a0,s1,540
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	77e080e7          	jalr	1918(ra) # 80002450 <wakeup>
  release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	06e080e7          	jalr	110(ra) # 80000d4a <release>
  return i;
}
    80004ce4:	854e                	mv	a0,s3
    80004ce6:	60a6                	ld	ra,72(sp)
    80004ce8:	6406                	ld	s0,64(sp)
    80004cea:	74e2                	ld	s1,56(sp)
    80004cec:	7942                	ld	s2,48(sp)
    80004cee:	79a2                	ld	s3,40(sp)
    80004cf0:	7a02                	ld	s4,32(sp)
    80004cf2:	6ae2                	ld	s5,24(sp)
    80004cf4:	6b42                	ld	s6,16(sp)
    80004cf6:	6161                	addi	sp,sp,80
    80004cf8:	8082                	ret
      release(&pi->lock);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	04e080e7          	jalr	78(ra) # 80000d4a <release>
      return -1;
    80004d04:	59fd                	li	s3,-1
    80004d06:	bff9                	j	80004ce4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d08:	4981                	li	s3,0
    80004d0a:	b7d1                	j	80004cce <piperead+0xae>

0000000080004d0c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d0c:	df010113          	addi	sp,sp,-528
    80004d10:	20113423          	sd	ra,520(sp)
    80004d14:	20813023          	sd	s0,512(sp)
    80004d18:	ffa6                	sd	s1,504(sp)
    80004d1a:	fbca                	sd	s2,496(sp)
    80004d1c:	f7ce                	sd	s3,488(sp)
    80004d1e:	f3d2                	sd	s4,480(sp)
    80004d20:	efd6                	sd	s5,472(sp)
    80004d22:	ebda                	sd	s6,464(sp)
    80004d24:	e7de                	sd	s7,456(sp)
    80004d26:	e3e2                	sd	s8,448(sp)
    80004d28:	ff66                	sd	s9,440(sp)
    80004d2a:	fb6a                	sd	s10,432(sp)
    80004d2c:	f76e                	sd	s11,424(sp)
    80004d2e:	0c00                	addi	s0,sp,528
    80004d30:	84aa                	mv	s1,a0
    80004d32:	dea43c23          	sd	a0,-520(s0)
    80004d36:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	d2a080e7          	jalr	-726(ra) # 80001a64 <myproc>
    80004d42:	892a                	mv	s2,a0

  begin_op();
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	446080e7          	jalr	1094(ra) # 8000418a <begin_op>

  if((ip = namei(path)) == 0){
    80004d4c:	8526                	mv	a0,s1
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	230080e7          	jalr	560(ra) # 80003f7e <namei>
    80004d56:	c92d                	beqz	a0,80004dc8 <exec+0xbc>
    80004d58:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	a74080e7          	jalr	-1420(ra) # 800037ce <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d62:	04000713          	li	a4,64
    80004d66:	4681                	li	a3,0
    80004d68:	e4840613          	addi	a2,s0,-440
    80004d6c:	4581                	li	a1,0
    80004d6e:	8526                	mv	a0,s1
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	d12080e7          	jalr	-750(ra) # 80003a82 <readi>
    80004d78:	04000793          	li	a5,64
    80004d7c:	00f51a63          	bne	a0,a5,80004d90 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d80:	e4842703          	lw	a4,-440(s0)
    80004d84:	464c47b7          	lui	a5,0x464c4
    80004d88:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d8c:	04f70463          	beq	a4,a5,80004dd4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d90:	8526                	mv	a0,s1
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	c9e080e7          	jalr	-866(ra) # 80003a30 <iunlockput>
    end_op();
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	470080e7          	jalr	1136(ra) # 8000420a <end_op>
  }
  return -1;
    80004da2:	557d                	li	a0,-1
}
    80004da4:	20813083          	ld	ra,520(sp)
    80004da8:	20013403          	ld	s0,512(sp)
    80004dac:	74fe                	ld	s1,504(sp)
    80004dae:	795e                	ld	s2,496(sp)
    80004db0:	79be                	ld	s3,488(sp)
    80004db2:	7a1e                	ld	s4,480(sp)
    80004db4:	6afe                	ld	s5,472(sp)
    80004db6:	6b5e                	ld	s6,464(sp)
    80004db8:	6bbe                	ld	s7,456(sp)
    80004dba:	6c1e                	ld	s8,448(sp)
    80004dbc:	7cfa                	ld	s9,440(sp)
    80004dbe:	7d5a                	ld	s10,432(sp)
    80004dc0:	7dba                	ld	s11,424(sp)
    80004dc2:	21010113          	addi	sp,sp,528
    80004dc6:	8082                	ret
    end_op();
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	442080e7          	jalr	1090(ra) # 8000420a <end_op>
    return -1;
    80004dd0:	557d                	li	a0,-1
    80004dd2:	bfc9                	j	80004da4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd4:	854a                	mv	a0,s2
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	d52080e7          	jalr	-686(ra) # 80001b28 <proc_pagetable>
    80004dde:	8baa                	mv	s7,a0
    80004de0:	d945                	beqz	a0,80004d90 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de2:	e6842983          	lw	s3,-408(s0)
    80004de6:	e8045783          	lhu	a5,-384(s0)
    80004dea:	c7ad                	beqz	a5,80004e54 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dec:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dee:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004df0:	6c85                	lui	s9,0x1
    80004df2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004df6:	def43823          	sd	a5,-528(s0)
    80004dfa:	a42d                	j	80005024 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dfc:	00004517          	auipc	a0,0x4
    80004e00:	90c50513          	addi	a0,a0,-1780 # 80008708 <syscalls+0x2a0>
    80004e04:	ffffb097          	auipc	ra,0xffffb
    80004e08:	7f4080e7          	jalr	2036(ra) # 800005f8 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e0c:	8756                	mv	a4,s5
    80004e0e:	012d86bb          	addw	a3,s11,s2
    80004e12:	4581                	li	a1,0
    80004e14:	8526                	mv	a0,s1
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	c6c080e7          	jalr	-916(ra) # 80003a82 <readi>
    80004e1e:	2501                	sext.w	a0,a0
    80004e20:	1aaa9963          	bne	s5,a0,80004fd2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e24:	6785                	lui	a5,0x1
    80004e26:	0127893b          	addw	s2,a5,s2
    80004e2a:	77fd                	lui	a5,0xfffff
    80004e2c:	01478a3b          	addw	s4,a5,s4
    80004e30:	1f897163          	bgeu	s2,s8,80005012 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e34:	02091593          	slli	a1,s2,0x20
    80004e38:	9181                	srli	a1,a1,0x20
    80004e3a:	95ea                	add	a1,a1,s10
    80004e3c:	855e                	mv	a0,s7
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	2e6080e7          	jalr	742(ra) # 80001124 <walkaddr>
    80004e46:	862a                	mv	a2,a0
    if(pa == 0)
    80004e48:	d955                	beqz	a0,80004dfc <exec+0xf0>
      n = PGSIZE;
    80004e4a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e4c:	fd9a70e3          	bgeu	s4,s9,80004e0c <exec+0x100>
      n = sz - i;
    80004e50:	8ad2                	mv	s5,s4
    80004e52:	bf6d                	j	80004e0c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e54:	4901                	li	s2,0
  iunlockput(ip);
    80004e56:	8526                	mv	a0,s1
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	bd8080e7          	jalr	-1064(ra) # 80003a30 <iunlockput>
  end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	3aa080e7          	jalr	938(ra) # 8000420a <end_op>
  p = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	bfc080e7          	jalr	-1028(ra) # 80001a64 <myproc>
    80004e70:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e72:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e76:	6785                	lui	a5,0x1
    80004e78:	17fd                	addi	a5,a5,-1
    80004e7a:	993e                	add	s2,s2,a5
    80004e7c:	757d                	lui	a0,0xfffff
    80004e7e:	00a977b3          	and	a5,s2,a0
    80004e82:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e86:	6609                	lui	a2,0x2
    80004e88:	963e                	add	a2,a2,a5
    80004e8a:	85be                	mv	a1,a5
    80004e8c:	855e                	mv	a0,s7
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	67a080e7          	jalr	1658(ra) # 80001508 <uvmalloc>
    80004e96:	8b2a                	mv	s6,a0
  ip = 0;
    80004e98:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e9a:	12050c63          	beqz	a0,80004fd2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e9e:	75f9                	lui	a1,0xffffe
    80004ea0:	95aa                	add	a1,a1,a0
    80004ea2:	855e                	mv	a0,s7
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	882080e7          	jalr	-1918(ra) # 80001726 <uvmclear>
  stackbase = sp - PGSIZE;
    80004eac:	7c7d                	lui	s8,0xfffff
    80004eae:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eb0:	e0043783          	ld	a5,-512(s0)
    80004eb4:	6388                	ld	a0,0(a5)
    80004eb6:	c535                	beqz	a0,80004f22 <exec+0x216>
    80004eb8:	e8840993          	addi	s3,s0,-376
    80004ebc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ec0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	058080e7          	jalr	88(ra) # 80000f1a <strlen>
    80004eca:	2505                	addiw	a0,a0,1
    80004ecc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ed0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ed4:	13896363          	bltu	s2,s8,80004ffa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ed8:	e0043d83          	ld	s11,-512(s0)
    80004edc:	000dba03          	ld	s4,0(s11)
    80004ee0:	8552                	mv	a0,s4
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	038080e7          	jalr	56(ra) # 80000f1a <strlen>
    80004eea:	0015069b          	addiw	a3,a0,1
    80004eee:	8652                	mv	a2,s4
    80004ef0:	85ca                	mv	a1,s2
    80004ef2:	855e                	mv	a0,s7
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	864080e7          	jalr	-1948(ra) # 80001758 <copyout>
    80004efc:	10054363          	bltz	a0,80005002 <exec+0x2f6>
    ustack[argc] = sp;
    80004f00:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f04:	0485                	addi	s1,s1,1
    80004f06:	008d8793          	addi	a5,s11,8
    80004f0a:	e0f43023          	sd	a5,-512(s0)
    80004f0e:	008db503          	ld	a0,8(s11)
    80004f12:	c911                	beqz	a0,80004f26 <exec+0x21a>
    if(argc >= MAXARG)
    80004f14:	09a1                	addi	s3,s3,8
    80004f16:	fb3c96e3          	bne	s9,s3,80004ec2 <exec+0x1b6>
  sz = sz1;
    80004f1a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f1e:	4481                	li	s1,0
    80004f20:	a84d                	j	80004fd2 <exec+0x2c6>
  sp = sz;
    80004f22:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f24:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f26:	00349793          	slli	a5,s1,0x3
    80004f2a:	f9040713          	addi	a4,s0,-112
    80004f2e:	97ba                	add	a5,a5,a4
    80004f30:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f34:	00148693          	addi	a3,s1,1
    80004f38:	068e                	slli	a3,a3,0x3
    80004f3a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f3e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f42:	01897663          	bgeu	s2,s8,80004f4e <exec+0x242>
  sz = sz1;
    80004f46:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f4a:	4481                	li	s1,0
    80004f4c:	a059                	j	80004fd2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f4e:	e8840613          	addi	a2,s0,-376
    80004f52:	85ca                	mv	a1,s2
    80004f54:	855e                	mv	a0,s7
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	802080e7          	jalr	-2046(ra) # 80001758 <copyout>
    80004f5e:	0a054663          	bltz	a0,8000500a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f62:	058ab783          	ld	a5,88(s5)
    80004f66:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f6a:	df843783          	ld	a5,-520(s0)
    80004f6e:	0007c703          	lbu	a4,0(a5)
    80004f72:	cf11                	beqz	a4,80004f8e <exec+0x282>
    80004f74:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f76:	02f00693          	li	a3,47
    80004f7a:	a029                	j	80004f84 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f7c:	0785                	addi	a5,a5,1
    80004f7e:	fff7c703          	lbu	a4,-1(a5)
    80004f82:	c711                	beqz	a4,80004f8e <exec+0x282>
    if(*s == '/')
    80004f84:	fed71ce3          	bne	a4,a3,80004f7c <exec+0x270>
      last = s+1;
    80004f88:	def43c23          	sd	a5,-520(s0)
    80004f8c:	bfc5                	j	80004f7c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f8e:	4641                	li	a2,16
    80004f90:	df843583          	ld	a1,-520(s0)
    80004f94:	158a8513          	addi	a0,s5,344
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	f50080e7          	jalr	-176(ra) # 80000ee8 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fa0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fa4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fa8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fac:	058ab783          	ld	a5,88(s5)
    80004fb0:	e6043703          	ld	a4,-416(s0)
    80004fb4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fb6:	058ab783          	ld	a5,88(s5)
    80004fba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fbe:	85ea                	mv	a1,s10
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	c04080e7          	jalr	-1020(ra) # 80001bc4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fc8:	0004851b          	sext.w	a0,s1
    80004fcc:	bbe1                	j	80004da4 <exec+0x98>
    80004fce:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fd2:	e0843583          	ld	a1,-504(s0)
    80004fd6:	855e                	mv	a0,s7
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	bec080e7          	jalr	-1044(ra) # 80001bc4 <proc_freepagetable>
  if(ip){
    80004fe0:	da0498e3          	bnez	s1,80004d90 <exec+0x84>
  return -1;
    80004fe4:	557d                	li	a0,-1
    80004fe6:	bb7d                	j	80004da4 <exec+0x98>
    80004fe8:	e1243423          	sd	s2,-504(s0)
    80004fec:	b7dd                	j	80004fd2 <exec+0x2c6>
    80004fee:	e1243423          	sd	s2,-504(s0)
    80004ff2:	b7c5                	j	80004fd2 <exec+0x2c6>
    80004ff4:	e1243423          	sd	s2,-504(s0)
    80004ff8:	bfe9                	j	80004fd2 <exec+0x2c6>
  sz = sz1;
    80004ffa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ffe:	4481                	li	s1,0
    80005000:	bfc9                	j	80004fd2 <exec+0x2c6>
  sz = sz1;
    80005002:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005006:	4481                	li	s1,0
    80005008:	b7e9                	j	80004fd2 <exec+0x2c6>
  sz = sz1;
    8000500a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500e:	4481                	li	s1,0
    80005010:	b7c9                	j	80004fd2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005012:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005016:	2b05                	addiw	s6,s6,1
    80005018:	0389899b          	addiw	s3,s3,56
    8000501c:	e8045783          	lhu	a5,-384(s0)
    80005020:	e2fb5be3          	bge	s6,a5,80004e56 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005024:	2981                	sext.w	s3,s3
    80005026:	03800713          	li	a4,56
    8000502a:	86ce                	mv	a3,s3
    8000502c:	e1040613          	addi	a2,s0,-496
    80005030:	4581                	li	a1,0
    80005032:	8526                	mv	a0,s1
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	a4e080e7          	jalr	-1458(ra) # 80003a82 <readi>
    8000503c:	03800793          	li	a5,56
    80005040:	f8f517e3          	bne	a0,a5,80004fce <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005044:	e1042783          	lw	a5,-496(s0)
    80005048:	4705                	li	a4,1
    8000504a:	fce796e3          	bne	a5,a4,80005016 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000504e:	e3843603          	ld	a2,-456(s0)
    80005052:	e3043783          	ld	a5,-464(s0)
    80005056:	f8f669e3          	bltu	a2,a5,80004fe8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000505a:	e2043783          	ld	a5,-480(s0)
    8000505e:	963e                	add	a2,a2,a5
    80005060:	f8f667e3          	bltu	a2,a5,80004fee <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005064:	85ca                	mv	a1,s2
    80005066:	855e                	mv	a0,s7
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	4a0080e7          	jalr	1184(ra) # 80001508 <uvmalloc>
    80005070:	e0a43423          	sd	a0,-504(s0)
    80005074:	d141                	beqz	a0,80004ff4 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005076:	e2043d03          	ld	s10,-480(s0)
    8000507a:	df043783          	ld	a5,-528(s0)
    8000507e:	00fd77b3          	and	a5,s10,a5
    80005082:	fba1                	bnez	a5,80004fd2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005084:	e1842d83          	lw	s11,-488(s0)
    80005088:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000508c:	f80c03e3          	beqz	s8,80005012 <exec+0x306>
    80005090:	8a62                	mv	s4,s8
    80005092:	4901                	li	s2,0
    80005094:	b345                	j	80004e34 <exec+0x128>

0000000080005096 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005096:	7179                	addi	sp,sp,-48
    80005098:	f406                	sd	ra,40(sp)
    8000509a:	f022                	sd	s0,32(sp)
    8000509c:	ec26                	sd	s1,24(sp)
    8000509e:	e84a                	sd	s2,16(sp)
    800050a0:	1800                	addi	s0,sp,48
    800050a2:	892e                	mv	s2,a1
    800050a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050a6:	fdc40593          	addi	a1,s0,-36
    800050aa:	ffffe097          	auipc	ra,0xffffe
    800050ae:	b1c080e7          	jalr	-1252(ra) # 80002bc6 <argint>
    800050b2:	04054063          	bltz	a0,800050f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050b6:	fdc42703          	lw	a4,-36(s0)
    800050ba:	47bd                	li	a5,15
    800050bc:	02e7ed63          	bltu	a5,a4,800050f6 <argfd+0x60>
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	9a4080e7          	jalr	-1628(ra) # 80001a64 <myproc>
    800050c8:	fdc42703          	lw	a4,-36(s0)
    800050cc:	01a70793          	addi	a5,a4,26
    800050d0:	078e                	slli	a5,a5,0x3
    800050d2:	953e                	add	a0,a0,a5
    800050d4:	611c                	ld	a5,0(a0)
    800050d6:	c395                	beqz	a5,800050fa <argfd+0x64>
    return -1;
  if(pfd)
    800050d8:	00090463          	beqz	s2,800050e0 <argfd+0x4a>
    *pfd = fd;
    800050dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050e0:	4501                	li	a0,0
  if(pf)
    800050e2:	c091                	beqz	s1,800050e6 <argfd+0x50>
    *pf = f;
    800050e4:	e09c                	sd	a5,0(s1)
}
    800050e6:	70a2                	ld	ra,40(sp)
    800050e8:	7402                	ld	s0,32(sp)
    800050ea:	64e2                	ld	s1,24(sp)
    800050ec:	6942                	ld	s2,16(sp)
    800050ee:	6145                	addi	sp,sp,48
    800050f0:	8082                	ret
    return -1;
    800050f2:	557d                	li	a0,-1
    800050f4:	bfcd                	j	800050e6 <argfd+0x50>
    return -1;
    800050f6:	557d                	li	a0,-1
    800050f8:	b7fd                	j	800050e6 <argfd+0x50>
    800050fa:	557d                	li	a0,-1
    800050fc:	b7ed                	j	800050e6 <argfd+0x50>

00000000800050fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050fe:	1101                	addi	sp,sp,-32
    80005100:	ec06                	sd	ra,24(sp)
    80005102:	e822                	sd	s0,16(sp)
    80005104:	e426                	sd	s1,8(sp)
    80005106:	1000                	addi	s0,sp,32
    80005108:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	95a080e7          	jalr	-1702(ra) # 80001a64 <myproc>
    80005112:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005114:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    80005118:	4501                	li	a0,0
    8000511a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000511c:	6398                	ld	a4,0(a5)
    8000511e:	cb19                	beqz	a4,80005134 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005120:	2505                	addiw	a0,a0,1
    80005122:	07a1                	addi	a5,a5,8
    80005124:	fed51ce3          	bne	a0,a3,8000511c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005128:	557d                	li	a0,-1
}
    8000512a:	60e2                	ld	ra,24(sp)
    8000512c:	6442                	ld	s0,16(sp)
    8000512e:	64a2                	ld	s1,8(sp)
    80005130:	6105                	addi	sp,sp,32
    80005132:	8082                	ret
      p->ofile[fd] = f;
    80005134:	01a50793          	addi	a5,a0,26
    80005138:	078e                	slli	a5,a5,0x3
    8000513a:	963e                	add	a2,a2,a5
    8000513c:	e204                	sd	s1,0(a2)
      return fd;
    8000513e:	b7f5                	j	8000512a <fdalloc+0x2c>

0000000080005140 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005140:	715d                	addi	sp,sp,-80
    80005142:	e486                	sd	ra,72(sp)
    80005144:	e0a2                	sd	s0,64(sp)
    80005146:	fc26                	sd	s1,56(sp)
    80005148:	f84a                	sd	s2,48(sp)
    8000514a:	f44e                	sd	s3,40(sp)
    8000514c:	f052                	sd	s4,32(sp)
    8000514e:	ec56                	sd	s5,24(sp)
    80005150:	0880                	addi	s0,sp,80
    80005152:	89ae                	mv	s3,a1
    80005154:	8ab2                	mv	s5,a2
    80005156:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005158:	fb040593          	addi	a1,s0,-80
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	e40080e7          	jalr	-448(ra) # 80003f9c <nameiparent>
    80005164:	892a                	mv	s2,a0
    80005166:	12050f63          	beqz	a0,800052a4 <create+0x164>
    return 0;

  ilock(dp);
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	664080e7          	jalr	1636(ra) # 800037ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005172:	4601                	li	a2,0
    80005174:	fb040593          	addi	a1,s0,-80
    80005178:	854a                	mv	a0,s2
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	b32080e7          	jalr	-1230(ra) # 80003cac <dirlookup>
    80005182:	84aa                	mv	s1,a0
    80005184:	c921                	beqz	a0,800051d4 <create+0x94>
    iunlockput(dp);
    80005186:	854a                	mv	a0,s2
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	8a8080e7          	jalr	-1880(ra) # 80003a30 <iunlockput>
    ilock(ip);
    80005190:	8526                	mv	a0,s1
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	63c080e7          	jalr	1596(ra) # 800037ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000519a:	2981                	sext.w	s3,s3
    8000519c:	4789                	li	a5,2
    8000519e:	02f99463          	bne	s3,a5,800051c6 <create+0x86>
    800051a2:	0444d783          	lhu	a5,68(s1)
    800051a6:	37f9                	addiw	a5,a5,-2
    800051a8:	17c2                	slli	a5,a5,0x30
    800051aa:	93c1                	srli	a5,a5,0x30
    800051ac:	4705                	li	a4,1
    800051ae:	00f76c63          	bltu	a4,a5,800051c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051b2:	8526                	mv	a0,s1
    800051b4:	60a6                	ld	ra,72(sp)
    800051b6:	6406                	ld	s0,64(sp)
    800051b8:	74e2                	ld	s1,56(sp)
    800051ba:	7942                	ld	s2,48(sp)
    800051bc:	79a2                	ld	s3,40(sp)
    800051be:	7a02                	ld	s4,32(sp)
    800051c0:	6ae2                	ld	s5,24(sp)
    800051c2:	6161                	addi	sp,sp,80
    800051c4:	8082                	ret
    iunlockput(ip);
    800051c6:	8526                	mv	a0,s1
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	868080e7          	jalr	-1944(ra) # 80003a30 <iunlockput>
    return 0;
    800051d0:	4481                	li	s1,0
    800051d2:	b7c5                	j	800051b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051d4:	85ce                	mv	a1,s3
    800051d6:	00092503          	lw	a0,0(s2)
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	45c080e7          	jalr	1116(ra) # 80003636 <ialloc>
    800051e2:	84aa                	mv	s1,a0
    800051e4:	c529                	beqz	a0,8000522e <create+0xee>
  ilock(ip);
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	5e8080e7          	jalr	1512(ra) # 800037ce <ilock>
  ip->major = major;
    800051ee:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051f2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051f6:	4785                	li	a5,1
    800051f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffe097          	auipc	ra,0xffffe
    80005202:	506080e7          	jalr	1286(ra) # 80003704 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005206:	2981                	sext.w	s3,s3
    80005208:	4785                	li	a5,1
    8000520a:	02f98a63          	beq	s3,a5,8000523e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000520e:	40d0                	lw	a2,4(s1)
    80005210:	fb040593          	addi	a1,s0,-80
    80005214:	854a                	mv	a0,s2
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	ca6080e7          	jalr	-858(ra) # 80003ebc <dirlink>
    8000521e:	06054b63          	bltz	a0,80005294 <create+0x154>
  iunlockput(dp);
    80005222:	854a                	mv	a0,s2
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	80c080e7          	jalr	-2036(ra) # 80003a30 <iunlockput>
  return ip;
    8000522c:	b759                	j	800051b2 <create+0x72>
    panic("create: ialloc");
    8000522e:	00003517          	auipc	a0,0x3
    80005232:	4fa50513          	addi	a0,a0,1274 # 80008728 <syscalls+0x2c0>
    80005236:	ffffb097          	auipc	ra,0xffffb
    8000523a:	3c2080e7          	jalr	962(ra) # 800005f8 <panic>
    dp->nlink++;  // for ".."
    8000523e:	04a95783          	lhu	a5,74(s2)
    80005242:	2785                	addiw	a5,a5,1
    80005244:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005248:	854a                	mv	a0,s2
    8000524a:	ffffe097          	auipc	ra,0xffffe
    8000524e:	4ba080e7          	jalr	1210(ra) # 80003704 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005252:	40d0                	lw	a2,4(s1)
    80005254:	00003597          	auipc	a1,0x3
    80005258:	4e458593          	addi	a1,a1,1252 # 80008738 <syscalls+0x2d0>
    8000525c:	8526                	mv	a0,s1
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	c5e080e7          	jalr	-930(ra) # 80003ebc <dirlink>
    80005266:	00054f63          	bltz	a0,80005284 <create+0x144>
    8000526a:	00492603          	lw	a2,4(s2)
    8000526e:	00003597          	auipc	a1,0x3
    80005272:	4d258593          	addi	a1,a1,1234 # 80008740 <syscalls+0x2d8>
    80005276:	8526                	mv	a0,s1
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	c44080e7          	jalr	-956(ra) # 80003ebc <dirlink>
    80005280:	f80557e3          	bgez	a0,8000520e <create+0xce>
      panic("create dots");
    80005284:	00003517          	auipc	a0,0x3
    80005288:	4c450513          	addi	a0,a0,1220 # 80008748 <syscalls+0x2e0>
    8000528c:	ffffb097          	auipc	ra,0xffffb
    80005290:	36c080e7          	jalr	876(ra) # 800005f8 <panic>
    panic("create: dirlink");
    80005294:	00003517          	auipc	a0,0x3
    80005298:	4c450513          	addi	a0,a0,1220 # 80008758 <syscalls+0x2f0>
    8000529c:	ffffb097          	auipc	ra,0xffffb
    800052a0:	35c080e7          	jalr	860(ra) # 800005f8 <panic>
    return 0;
    800052a4:	84aa                	mv	s1,a0
    800052a6:	b731                	j	800051b2 <create+0x72>

00000000800052a8 <sys_dup>:
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	ec26                	sd	s1,24(sp)
    800052b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b2:	fd840613          	addi	a2,s0,-40
    800052b6:	4581                	li	a1,0
    800052b8:	4501                	li	a0,0
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	ddc080e7          	jalr	-548(ra) # 80005096 <argfd>
    return -1;
    800052c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c4:	02054363          	bltz	a0,800052ea <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052c8:	fd843503          	ld	a0,-40(s0)
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	e32080e7          	jalr	-462(ra) # 800050fe <fdalloc>
    800052d4:	84aa                	mv	s1,a0
    return -1;
    800052d6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052d8:	00054963          	bltz	a0,800052ea <sys_dup+0x42>
  filedup(f);
    800052dc:	fd843503          	ld	a0,-40(s0)
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	32a080e7          	jalr	810(ra) # 8000460a <filedup>
  return fd;
    800052e8:	87a6                	mv	a5,s1
}
    800052ea:	853e                	mv	a0,a5
    800052ec:	70a2                	ld	ra,40(sp)
    800052ee:	7402                	ld	s0,32(sp)
    800052f0:	64e2                	ld	s1,24(sp)
    800052f2:	6145                	addi	sp,sp,48
    800052f4:	8082                	ret

00000000800052f6 <sys_read>:
{
    800052f6:	7179                	addi	sp,sp,-48
    800052f8:	f406                	sd	ra,40(sp)
    800052fa:	f022                	sd	s0,32(sp)
    800052fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fe:	fe840613          	addi	a2,s0,-24
    80005302:	4581                	li	a1,0
    80005304:	4501                	li	a0,0
    80005306:	00000097          	auipc	ra,0x0
    8000530a:	d90080e7          	jalr	-624(ra) # 80005096 <argfd>
    return -1;
    8000530e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005310:	04054163          	bltz	a0,80005352 <sys_read+0x5c>
    80005314:	fe440593          	addi	a1,s0,-28
    80005318:	4509                	li	a0,2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	8ac080e7          	jalr	-1876(ra) # 80002bc6 <argint>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005324:	02054763          	bltz	a0,80005352 <sys_read+0x5c>
    80005328:	fd840593          	addi	a1,s0,-40
    8000532c:	4505                	li	a0,1
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	8ba080e7          	jalr	-1862(ra) # 80002be8 <argaddr>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	00054d63          	bltz	a0,80005352 <sys_read+0x5c>
  return fileread(f, p, n);
    8000533c:	fe442603          	lw	a2,-28(s0)
    80005340:	fd843583          	ld	a1,-40(s0)
    80005344:	fe843503          	ld	a0,-24(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	44e080e7          	jalr	1102(ra) # 80004796 <fileread>
    80005350:	87aa                	mv	a5,a0
}
    80005352:	853e                	mv	a0,a5
    80005354:	70a2                	ld	ra,40(sp)
    80005356:	7402                	ld	s0,32(sp)
    80005358:	6145                	addi	sp,sp,48
    8000535a:	8082                	ret

000000008000535c <sys_write>:
{
    8000535c:	7179                	addi	sp,sp,-48
    8000535e:	f406                	sd	ra,40(sp)
    80005360:	f022                	sd	s0,32(sp)
    80005362:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005364:	fe840613          	addi	a2,s0,-24
    80005368:	4581                	li	a1,0
    8000536a:	4501                	li	a0,0
    8000536c:	00000097          	auipc	ra,0x0
    80005370:	d2a080e7          	jalr	-726(ra) # 80005096 <argfd>
    return -1;
    80005374:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005376:	04054163          	bltz	a0,800053b8 <sys_write+0x5c>
    8000537a:	fe440593          	addi	a1,s0,-28
    8000537e:	4509                	li	a0,2
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	846080e7          	jalr	-1978(ra) # 80002bc6 <argint>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538a:	02054763          	bltz	a0,800053b8 <sys_write+0x5c>
    8000538e:	fd840593          	addi	a1,s0,-40
    80005392:	4505                	li	a0,1
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	854080e7          	jalr	-1964(ra) # 80002be8 <argaddr>
    return -1;
    8000539c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539e:	00054d63          	bltz	a0,800053b8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053a2:	fe442603          	lw	a2,-28(s0)
    800053a6:	fd843583          	ld	a1,-40(s0)
    800053aa:	fe843503          	ld	a0,-24(s0)
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	4aa080e7          	jalr	1194(ra) # 80004858 <filewrite>
    800053b6:	87aa                	mv	a5,a0
}
    800053b8:	853e                	mv	a0,a5
    800053ba:	70a2                	ld	ra,40(sp)
    800053bc:	7402                	ld	s0,32(sp)
    800053be:	6145                	addi	sp,sp,48
    800053c0:	8082                	ret

00000000800053c2 <sys_close>:
{
    800053c2:	1101                	addi	sp,sp,-32
    800053c4:	ec06                	sd	ra,24(sp)
    800053c6:	e822                	sd	s0,16(sp)
    800053c8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053ca:	fe040613          	addi	a2,s0,-32
    800053ce:	fec40593          	addi	a1,s0,-20
    800053d2:	4501                	li	a0,0
    800053d4:	00000097          	auipc	ra,0x0
    800053d8:	cc2080e7          	jalr	-830(ra) # 80005096 <argfd>
    return -1;
    800053dc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053de:	02054463          	bltz	a0,80005406 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	682080e7          	jalr	1666(ra) # 80001a64 <myproc>
    800053ea:	fec42783          	lw	a5,-20(s0)
    800053ee:	07e9                	addi	a5,a5,26
    800053f0:	078e                	slli	a5,a5,0x3
    800053f2:	97aa                	add	a5,a5,a0
    800053f4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053f8:	fe043503          	ld	a0,-32(s0)
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	260080e7          	jalr	608(ra) # 8000465c <fileclose>
  return 0;
    80005404:	4781                	li	a5,0
}
    80005406:	853e                	mv	a0,a5
    80005408:	60e2                	ld	ra,24(sp)
    8000540a:	6442                	ld	s0,16(sp)
    8000540c:	6105                	addi	sp,sp,32
    8000540e:	8082                	ret

0000000080005410 <sys_fstat>:
{
    80005410:	1101                	addi	sp,sp,-32
    80005412:	ec06                	sd	ra,24(sp)
    80005414:	e822                	sd	s0,16(sp)
    80005416:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005418:	fe840613          	addi	a2,s0,-24
    8000541c:	4581                	li	a1,0
    8000541e:	4501                	li	a0,0
    80005420:	00000097          	auipc	ra,0x0
    80005424:	c76080e7          	jalr	-906(ra) # 80005096 <argfd>
    return -1;
    80005428:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542a:	02054563          	bltz	a0,80005454 <sys_fstat+0x44>
    8000542e:	fe040593          	addi	a1,s0,-32
    80005432:	4505                	li	a0,1
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	7b4080e7          	jalr	1972(ra) # 80002be8 <argaddr>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000543e:	00054b63          	bltz	a0,80005454 <sys_fstat+0x44>
  return filestat(f, st);
    80005442:	fe043583          	ld	a1,-32(s0)
    80005446:	fe843503          	ld	a0,-24(s0)
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	2da080e7          	jalr	730(ra) # 80004724 <filestat>
    80005452:	87aa                	mv	a5,a0
}
    80005454:	853e                	mv	a0,a5
    80005456:	60e2                	ld	ra,24(sp)
    80005458:	6442                	ld	s0,16(sp)
    8000545a:	6105                	addi	sp,sp,32
    8000545c:	8082                	ret

000000008000545e <sys_link>:
{
    8000545e:	7169                	addi	sp,sp,-304
    80005460:	f606                	sd	ra,296(sp)
    80005462:	f222                	sd	s0,288(sp)
    80005464:	ee26                	sd	s1,280(sp)
    80005466:	ea4a                	sd	s2,272(sp)
    80005468:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546a:	08000613          	li	a2,128
    8000546e:	ed040593          	addi	a1,s0,-304
    80005472:	4501                	li	a0,0
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	796080e7          	jalr	1942(ra) # 80002c0a <argstr>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547e:	10054e63          	bltz	a0,8000559a <sys_link+0x13c>
    80005482:	08000613          	li	a2,128
    80005486:	f5040593          	addi	a1,s0,-176
    8000548a:	4505                	li	a0,1
    8000548c:	ffffd097          	auipc	ra,0xffffd
    80005490:	77e080e7          	jalr	1918(ra) # 80002c0a <argstr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005496:	10054263          	bltz	a0,8000559a <sys_link+0x13c>
  begin_op();
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	cf0080e7          	jalr	-784(ra) # 8000418a <begin_op>
  if((ip = namei(old)) == 0){
    800054a2:	ed040513          	addi	a0,s0,-304
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	ad8080e7          	jalr	-1320(ra) # 80003f7e <namei>
    800054ae:	84aa                	mv	s1,a0
    800054b0:	c551                	beqz	a0,8000553c <sys_link+0xde>
  ilock(ip);
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	31c080e7          	jalr	796(ra) # 800037ce <ilock>
  if(ip->type == T_DIR){
    800054ba:	04449703          	lh	a4,68(s1)
    800054be:	4785                	li	a5,1
    800054c0:	08f70463          	beq	a4,a5,80005548 <sys_link+0xea>
  ip->nlink++;
    800054c4:	04a4d783          	lhu	a5,74(s1)
    800054c8:	2785                	addiw	a5,a5,1
    800054ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	234080e7          	jalr	564(ra) # 80003704 <iupdate>
  iunlock(ip);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	3b6080e7          	jalr	950(ra) # 80003890 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054e2:	fd040593          	addi	a1,s0,-48
    800054e6:	f5040513          	addi	a0,s0,-176
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	ab2080e7          	jalr	-1358(ra) # 80003f9c <nameiparent>
    800054f2:	892a                	mv	s2,a0
    800054f4:	c935                	beqz	a0,80005568 <sys_link+0x10a>
  ilock(dp);
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	2d8080e7          	jalr	728(ra) # 800037ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054fe:	00092703          	lw	a4,0(s2)
    80005502:	409c                	lw	a5,0(s1)
    80005504:	04f71d63          	bne	a4,a5,8000555e <sys_link+0x100>
    80005508:	40d0                	lw	a2,4(s1)
    8000550a:	fd040593          	addi	a1,s0,-48
    8000550e:	854a                	mv	a0,s2
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	9ac080e7          	jalr	-1620(ra) # 80003ebc <dirlink>
    80005518:	04054363          	bltz	a0,8000555e <sys_link+0x100>
  iunlockput(dp);
    8000551c:	854a                	mv	a0,s2
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	512080e7          	jalr	1298(ra) # 80003a30 <iunlockput>
  iput(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	460080e7          	jalr	1120(ra) # 80003988 <iput>
  end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	cda080e7          	jalr	-806(ra) # 8000420a <end_op>
  return 0;
    80005538:	4781                	li	a5,0
    8000553a:	a085                	j	8000559a <sys_link+0x13c>
    end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	cce080e7          	jalr	-818(ra) # 8000420a <end_op>
    return -1;
    80005544:	57fd                	li	a5,-1
    80005546:	a891                	j	8000559a <sys_link+0x13c>
    iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	4e6080e7          	jalr	1254(ra) # 80003a30 <iunlockput>
    end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	cb8080e7          	jalr	-840(ra) # 8000420a <end_op>
    return -1;
    8000555a:	57fd                	li	a5,-1
    8000555c:	a83d                	j	8000559a <sys_link+0x13c>
    iunlockput(dp);
    8000555e:	854a                	mv	a0,s2
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	4d0080e7          	jalr	1232(ra) # 80003a30 <iunlockput>
  ilock(ip);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	264080e7          	jalr	612(ra) # 800037ce <ilock>
  ip->nlink--;
    80005572:	04a4d783          	lhu	a5,74(s1)
    80005576:	37fd                	addiw	a5,a5,-1
    80005578:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	186080e7          	jalr	390(ra) # 80003704 <iupdate>
  iunlockput(ip);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	4a8080e7          	jalr	1192(ra) # 80003a30 <iunlockput>
  end_op();
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	c7a080e7          	jalr	-902(ra) # 8000420a <end_op>
  return -1;
    80005598:	57fd                	li	a5,-1
}
    8000559a:	853e                	mv	a0,a5
    8000559c:	70b2                	ld	ra,296(sp)
    8000559e:	7412                	ld	s0,288(sp)
    800055a0:	64f2                	ld	s1,280(sp)
    800055a2:	6952                	ld	s2,272(sp)
    800055a4:	6155                	addi	sp,sp,304
    800055a6:	8082                	ret

00000000800055a8 <sys_unlink>:
{
    800055a8:	7151                	addi	sp,sp,-240
    800055aa:	f586                	sd	ra,232(sp)
    800055ac:	f1a2                	sd	s0,224(sp)
    800055ae:	eda6                	sd	s1,216(sp)
    800055b0:	e9ca                	sd	s2,208(sp)
    800055b2:	e5ce                	sd	s3,200(sp)
    800055b4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055b6:	08000613          	li	a2,128
    800055ba:	f3040593          	addi	a1,s0,-208
    800055be:	4501                	li	a0,0
    800055c0:	ffffd097          	auipc	ra,0xffffd
    800055c4:	64a080e7          	jalr	1610(ra) # 80002c0a <argstr>
    800055c8:	18054163          	bltz	a0,8000574a <sys_unlink+0x1a2>
  begin_op();
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	bbe080e7          	jalr	-1090(ra) # 8000418a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	f3040513          	addi	a0,s0,-208
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	9c0080e7          	jalr	-1600(ra) # 80003f9c <nameiparent>
    800055e4:	84aa                	mv	s1,a0
    800055e6:	c979                	beqz	a0,800056bc <sys_unlink+0x114>
  ilock(dp);
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	1e6080e7          	jalr	486(ra) # 800037ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f0:	00003597          	auipc	a1,0x3
    800055f4:	14858593          	addi	a1,a1,328 # 80008738 <syscalls+0x2d0>
    800055f8:	fb040513          	addi	a0,s0,-80
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	696080e7          	jalr	1686(ra) # 80003c92 <namecmp>
    80005604:	14050a63          	beqz	a0,80005758 <sys_unlink+0x1b0>
    80005608:	00003597          	auipc	a1,0x3
    8000560c:	13858593          	addi	a1,a1,312 # 80008740 <syscalls+0x2d8>
    80005610:	fb040513          	addi	a0,s0,-80
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	67e080e7          	jalr	1662(ra) # 80003c92 <namecmp>
    8000561c:	12050e63          	beqz	a0,80005758 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005620:	f2c40613          	addi	a2,s0,-212
    80005624:	fb040593          	addi	a1,s0,-80
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	682080e7          	jalr	1666(ra) # 80003cac <dirlookup>
    80005632:	892a                	mv	s2,a0
    80005634:	12050263          	beqz	a0,80005758 <sys_unlink+0x1b0>
  ilock(ip);
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	196080e7          	jalr	406(ra) # 800037ce <ilock>
  if(ip->nlink < 1)
    80005640:	04a91783          	lh	a5,74(s2)
    80005644:	08f05263          	blez	a5,800056c8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005648:	04491703          	lh	a4,68(s2)
    8000564c:	4785                	li	a5,1
    8000564e:	08f70563          	beq	a4,a5,800056d8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005652:	4641                	li	a2,16
    80005654:	4581                	li	a1,0
    80005656:	fc040513          	addi	a0,s0,-64
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	738080e7          	jalr	1848(ra) # 80000d92 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005662:	4741                	li	a4,16
    80005664:	f2c42683          	lw	a3,-212(s0)
    80005668:	fc040613          	addi	a2,s0,-64
    8000566c:	4581                	li	a1,0
    8000566e:	8526                	mv	a0,s1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	508080e7          	jalr	1288(ra) # 80003b78 <writei>
    80005678:	47c1                	li	a5,16
    8000567a:	0af51563          	bne	a0,a5,80005724 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000567e:	04491703          	lh	a4,68(s2)
    80005682:	4785                	li	a5,1
    80005684:	0af70863          	beq	a4,a5,80005734 <sys_unlink+0x18c>
  iunlockput(dp);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	3a6080e7          	jalr	934(ra) # 80003a30 <iunlockput>
  ip->nlink--;
    80005692:	04a95783          	lhu	a5,74(s2)
    80005696:	37fd                	addiw	a5,a5,-1
    80005698:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	066080e7          	jalr	102(ra) # 80003704 <iupdate>
  iunlockput(ip);
    800056a6:	854a                	mv	a0,s2
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	388080e7          	jalr	904(ra) # 80003a30 <iunlockput>
  end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	b5a080e7          	jalr	-1190(ra) # 8000420a <end_op>
  return 0;
    800056b8:	4501                	li	a0,0
    800056ba:	a84d                	j	8000576c <sys_unlink+0x1c4>
    end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	b4e080e7          	jalr	-1202(ra) # 8000420a <end_op>
    return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	a05d                	j	8000576c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056c8:	00003517          	auipc	a0,0x3
    800056cc:	0a050513          	addi	a0,a0,160 # 80008768 <syscalls+0x300>
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	f28080e7          	jalr	-216(ra) # 800005f8 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d8:	04c92703          	lw	a4,76(s2)
    800056dc:	02000793          	li	a5,32
    800056e0:	f6e7f9e3          	bgeu	a5,a4,80005652 <sys_unlink+0xaa>
    800056e4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056e8:	4741                	li	a4,16
    800056ea:	86ce                	mv	a3,s3
    800056ec:	f1840613          	addi	a2,s0,-232
    800056f0:	4581                	li	a1,0
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	38e080e7          	jalr	910(ra) # 80003a82 <readi>
    800056fc:	47c1                	li	a5,16
    800056fe:	00f51b63          	bne	a0,a5,80005714 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005702:	f1845783          	lhu	a5,-232(s0)
    80005706:	e7a1                	bnez	a5,8000574e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005708:	29c1                	addiw	s3,s3,16
    8000570a:	04c92783          	lw	a5,76(s2)
    8000570e:	fcf9ede3          	bltu	s3,a5,800056e8 <sys_unlink+0x140>
    80005712:	b781                	j	80005652 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005714:	00003517          	auipc	a0,0x3
    80005718:	06c50513          	addi	a0,a0,108 # 80008780 <syscalls+0x318>
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	edc080e7          	jalr	-292(ra) # 800005f8 <panic>
    panic("unlink: writei");
    80005724:	00003517          	auipc	a0,0x3
    80005728:	07450513          	addi	a0,a0,116 # 80008798 <syscalls+0x330>
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	ecc080e7          	jalr	-308(ra) # 800005f8 <panic>
    dp->nlink--;
    80005734:	04a4d783          	lhu	a5,74(s1)
    80005738:	37fd                	addiw	a5,a5,-1
    8000573a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	fc4080e7          	jalr	-60(ra) # 80003704 <iupdate>
    80005748:	b781                	j	80005688 <sys_unlink+0xe0>
    return -1;
    8000574a:	557d                	li	a0,-1
    8000574c:	a005                	j	8000576c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000574e:	854a                	mv	a0,s2
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	2e0080e7          	jalr	736(ra) # 80003a30 <iunlockput>
  iunlockput(dp);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	2d6080e7          	jalr	726(ra) # 80003a30 <iunlockput>
  end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	aa8080e7          	jalr	-1368(ra) # 8000420a <end_op>
  return -1;
    8000576a:	557d                	li	a0,-1
}
    8000576c:	70ae                	ld	ra,232(sp)
    8000576e:	740e                	ld	s0,224(sp)
    80005770:	64ee                	ld	s1,216(sp)
    80005772:	694e                	ld	s2,208(sp)
    80005774:	69ae                	ld	s3,200(sp)
    80005776:	616d                	addi	sp,sp,240
    80005778:	8082                	ret

000000008000577a <sys_open>:

uint64
sys_open(void)
{
    8000577a:	7131                	addi	sp,sp,-192
    8000577c:	fd06                	sd	ra,184(sp)
    8000577e:	f922                	sd	s0,176(sp)
    80005780:	f526                	sd	s1,168(sp)
    80005782:	f14a                	sd	s2,160(sp)
    80005784:	ed4e                	sd	s3,152(sp)
    80005786:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005788:	08000613          	li	a2,128
    8000578c:	f5040593          	addi	a1,s0,-176
    80005790:	4501                	li	a0,0
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	478080e7          	jalr	1144(ra) # 80002c0a <argstr>
    return -1;
    8000579a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000579c:	0c054163          	bltz	a0,8000585e <sys_open+0xe4>
    800057a0:	f4c40593          	addi	a1,s0,-180
    800057a4:	4505                	li	a0,1
    800057a6:	ffffd097          	auipc	ra,0xffffd
    800057aa:	420080e7          	jalr	1056(ra) # 80002bc6 <argint>
    800057ae:	0a054863          	bltz	a0,8000585e <sys_open+0xe4>

  begin_op();
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	9d8080e7          	jalr	-1576(ra) # 8000418a <begin_op>

  if(omode & O_CREATE){
    800057ba:	f4c42783          	lw	a5,-180(s0)
    800057be:	2007f793          	andi	a5,a5,512
    800057c2:	cbdd                	beqz	a5,80005878 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057c4:	4681                	li	a3,0
    800057c6:	4601                	li	a2,0
    800057c8:	4589                	li	a1,2
    800057ca:	f5040513          	addi	a0,s0,-176
    800057ce:	00000097          	auipc	ra,0x0
    800057d2:	972080e7          	jalr	-1678(ra) # 80005140 <create>
    800057d6:	892a                	mv	s2,a0
    if(ip == 0){
    800057d8:	c959                	beqz	a0,8000586e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	478d                	li	a5,3
    800057e0:	00f71763          	bne	a4,a5,800057ee <sys_open+0x74>
    800057e4:	04695703          	lhu	a4,70(s2)
    800057e8:	47a5                	li	a5,9
    800057ea:	0ce7ec63          	bltu	a5,a4,800058c2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	db2080e7          	jalr	-590(ra) # 800045a0 <filealloc>
    800057f6:	89aa                	mv	s3,a0
    800057f8:	10050263          	beqz	a0,800058fc <sys_open+0x182>
    800057fc:	00000097          	auipc	ra,0x0
    80005800:	902080e7          	jalr	-1790(ra) # 800050fe <fdalloc>
    80005804:	84aa                	mv	s1,a0
    80005806:	0e054663          	bltz	a0,800058f2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000580a:	04491703          	lh	a4,68(s2)
    8000580e:	478d                	li	a5,3
    80005810:	0cf70463          	beq	a4,a5,800058d8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005814:	4789                	li	a5,2
    80005816:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000581a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000581e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005822:	f4c42783          	lw	a5,-180(s0)
    80005826:	0017c713          	xori	a4,a5,1
    8000582a:	8b05                	andi	a4,a4,1
    8000582c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005830:	0037f713          	andi	a4,a5,3
    80005834:	00e03733          	snez	a4,a4
    80005838:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000583c:	4007f793          	andi	a5,a5,1024
    80005840:	c791                	beqz	a5,8000584c <sys_open+0xd2>
    80005842:	04491703          	lh	a4,68(s2)
    80005846:	4789                	li	a5,2
    80005848:	08f70f63          	beq	a4,a5,800058e6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	042080e7          	jalr	66(ra) # 80003890 <iunlock>
  end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	9b4080e7          	jalr	-1612(ra) # 8000420a <end_op>

  return fd;
}
    8000585e:	8526                	mv	a0,s1
    80005860:	70ea                	ld	ra,184(sp)
    80005862:	744a                	ld	s0,176(sp)
    80005864:	74aa                	ld	s1,168(sp)
    80005866:	790a                	ld	s2,160(sp)
    80005868:	69ea                	ld	s3,152(sp)
    8000586a:	6129                	addi	sp,sp,192
    8000586c:	8082                	ret
      end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	99c080e7          	jalr	-1636(ra) # 8000420a <end_op>
      return -1;
    80005876:	b7e5                	j	8000585e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005878:	f5040513          	addi	a0,s0,-176
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	702080e7          	jalr	1794(ra) # 80003f7e <namei>
    80005884:	892a                	mv	s2,a0
    80005886:	c905                	beqz	a0,800058b6 <sys_open+0x13c>
    ilock(ip);
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	f46080e7          	jalr	-186(ra) # 800037ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005890:	04491703          	lh	a4,68(s2)
    80005894:	4785                	li	a5,1
    80005896:	f4f712e3          	bne	a4,a5,800057da <sys_open+0x60>
    8000589a:	f4c42783          	lw	a5,-180(s0)
    8000589e:	dba1                	beqz	a5,800057ee <sys_open+0x74>
      iunlockput(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	18e080e7          	jalr	398(ra) # 80003a30 <iunlockput>
      end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	960080e7          	jalr	-1696(ra) # 8000420a <end_op>
      return -1;
    800058b2:	54fd                	li	s1,-1
    800058b4:	b76d                	j	8000585e <sys_open+0xe4>
      end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	954080e7          	jalr	-1708(ra) # 8000420a <end_op>
      return -1;
    800058be:	54fd                	li	s1,-1
    800058c0:	bf79                	j	8000585e <sys_open+0xe4>
    iunlockput(ip);
    800058c2:	854a                	mv	a0,s2
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	16c080e7          	jalr	364(ra) # 80003a30 <iunlockput>
    end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	93e080e7          	jalr	-1730(ra) # 8000420a <end_op>
    return -1;
    800058d4:	54fd                	li	s1,-1
    800058d6:	b761                	j	8000585e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058d8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058dc:	04691783          	lh	a5,70(s2)
    800058e0:	02f99223          	sh	a5,36(s3)
    800058e4:	bf2d                	j	8000581e <sys_open+0xa4>
    itrunc(ip);
    800058e6:	854a                	mv	a0,s2
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	ff4080e7          	jalr	-12(ra) # 800038dc <itrunc>
    800058f0:	bfb1                	j	8000584c <sys_open+0xd2>
      fileclose(f);
    800058f2:	854e                	mv	a0,s3
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	d68080e7          	jalr	-664(ra) # 8000465c <fileclose>
    iunlockput(ip);
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	132080e7          	jalr	306(ra) # 80003a30 <iunlockput>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	904080e7          	jalr	-1788(ra) # 8000420a <end_op>
    return -1;
    8000590e:	54fd                	li	s1,-1
    80005910:	b7b9                	j	8000585e <sys_open+0xe4>

0000000080005912 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005912:	7175                	addi	sp,sp,-144
    80005914:	e506                	sd	ra,136(sp)
    80005916:	e122                	sd	s0,128(sp)
    80005918:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	870080e7          	jalr	-1936(ra) # 8000418a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005922:	08000613          	li	a2,128
    80005926:	f7040593          	addi	a1,s0,-144
    8000592a:	4501                	li	a0,0
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	2de080e7          	jalr	734(ra) # 80002c0a <argstr>
    80005934:	02054963          	bltz	a0,80005966 <sys_mkdir+0x54>
    80005938:	4681                	li	a3,0
    8000593a:	4601                	li	a2,0
    8000593c:	4585                	li	a1,1
    8000593e:	f7040513          	addi	a0,s0,-144
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	7fe080e7          	jalr	2046(ra) # 80005140 <create>
    8000594a:	cd11                	beqz	a0,80005966 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	0e4080e7          	jalr	228(ra) # 80003a30 <iunlockput>
  end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	8b6080e7          	jalr	-1866(ra) # 8000420a <end_op>
  return 0;
    8000595c:	4501                	li	a0,0
}
    8000595e:	60aa                	ld	ra,136(sp)
    80005960:	640a                	ld	s0,128(sp)
    80005962:	6149                	addi	sp,sp,144
    80005964:	8082                	ret
    end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	8a4080e7          	jalr	-1884(ra) # 8000420a <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	b7fd                	j	8000595e <sys_mkdir+0x4c>

0000000080005972 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005972:	7135                	addi	sp,sp,-160
    80005974:	ed06                	sd	ra,152(sp)
    80005976:	e922                	sd	s0,144(sp)
    80005978:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	810080e7          	jalr	-2032(ra) # 8000418a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005982:	08000613          	li	a2,128
    80005986:	f7040593          	addi	a1,s0,-144
    8000598a:	4501                	li	a0,0
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	27e080e7          	jalr	638(ra) # 80002c0a <argstr>
    80005994:	04054a63          	bltz	a0,800059e8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005998:	f6c40593          	addi	a1,s0,-148
    8000599c:	4505                	li	a0,1
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	228080e7          	jalr	552(ra) # 80002bc6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a6:	04054163          	bltz	a0,800059e8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059aa:	f6840593          	addi	a1,s0,-152
    800059ae:	4509                	li	a0,2
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	216080e7          	jalr	534(ra) # 80002bc6 <argint>
     argint(1, &major) < 0 ||
    800059b8:	02054863          	bltz	a0,800059e8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059bc:	f6841683          	lh	a3,-152(s0)
    800059c0:	f6c41603          	lh	a2,-148(s0)
    800059c4:	458d                	li	a1,3
    800059c6:	f7040513          	addi	a0,s0,-144
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	776080e7          	jalr	1910(ra) # 80005140 <create>
     argint(2, &minor) < 0 ||
    800059d2:	c919                	beqz	a0,800059e8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	05c080e7          	jalr	92(ra) # 80003a30 <iunlockput>
  end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	82e080e7          	jalr	-2002(ra) # 8000420a <end_op>
  return 0;
    800059e4:	4501                	li	a0,0
    800059e6:	a031                	j	800059f2 <sys_mknod+0x80>
    end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	822080e7          	jalr	-2014(ra) # 8000420a <end_op>
    return -1;
    800059f0:	557d                	li	a0,-1
}
    800059f2:	60ea                	ld	ra,152(sp)
    800059f4:	644a                	ld	s0,144(sp)
    800059f6:	610d                	addi	sp,sp,160
    800059f8:	8082                	ret

00000000800059fa <sys_chdir>:

uint64
sys_chdir(void)
{
    800059fa:	7135                	addi	sp,sp,-160
    800059fc:	ed06                	sd	ra,152(sp)
    800059fe:	e922                	sd	s0,144(sp)
    80005a00:	e526                	sd	s1,136(sp)
    80005a02:	e14a                	sd	s2,128(sp)
    80005a04:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a06:	ffffc097          	auipc	ra,0xffffc
    80005a0a:	05e080e7          	jalr	94(ra) # 80001a64 <myproc>
    80005a0e:	892a                	mv	s2,a0
  
  begin_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	77a080e7          	jalr	1914(ra) # 8000418a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a18:	08000613          	li	a2,128
    80005a1c:	f6040593          	addi	a1,s0,-160
    80005a20:	4501                	li	a0,0
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	1e8080e7          	jalr	488(ra) # 80002c0a <argstr>
    80005a2a:	04054b63          	bltz	a0,80005a80 <sys_chdir+0x86>
    80005a2e:	f6040513          	addi	a0,s0,-160
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	54c080e7          	jalr	1356(ra) # 80003f7e <namei>
    80005a3a:	84aa                	mv	s1,a0
    80005a3c:	c131                	beqz	a0,80005a80 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	d90080e7          	jalr	-624(ra) # 800037ce <ilock>
  if(ip->type != T_DIR){
    80005a46:	04449703          	lh	a4,68(s1)
    80005a4a:	4785                	li	a5,1
    80005a4c:	04f71063          	bne	a4,a5,80005a8c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a50:	8526                	mv	a0,s1
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	e3e080e7          	jalr	-450(ra) # 80003890 <iunlock>
  iput(p->cwd);
    80005a5a:	15093503          	ld	a0,336(s2)
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	f2a080e7          	jalr	-214(ra) # 80003988 <iput>
  end_op();
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	7a4080e7          	jalr	1956(ra) # 8000420a <end_op>
  p->cwd = ip;
    80005a6e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a72:	4501                	li	a0,0
}
    80005a74:	60ea                	ld	ra,152(sp)
    80005a76:	644a                	ld	s0,144(sp)
    80005a78:	64aa                	ld	s1,136(sp)
    80005a7a:	690a                	ld	s2,128(sp)
    80005a7c:	610d                	addi	sp,sp,160
    80005a7e:	8082                	ret
    end_op();
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	78a080e7          	jalr	1930(ra) # 8000420a <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	b7ed                	j	80005a74 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	fa2080e7          	jalr	-94(ra) # 80003a30 <iunlockput>
    end_op();
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	774080e7          	jalr	1908(ra) # 8000420a <end_op>
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	bfd1                	j	80005a74 <sys_chdir+0x7a>

0000000080005aa2 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa2:	7145                	addi	sp,sp,-464
    80005aa4:	e786                	sd	ra,456(sp)
    80005aa6:	e3a2                	sd	s0,448(sp)
    80005aa8:	ff26                	sd	s1,440(sp)
    80005aaa:	fb4a                	sd	s2,432(sp)
    80005aac:	f74e                	sd	s3,424(sp)
    80005aae:	f352                	sd	s4,416(sp)
    80005ab0:	ef56                	sd	s5,408(sp)
    80005ab2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab4:	08000613          	li	a2,128
    80005ab8:	f4040593          	addi	a1,s0,-192
    80005abc:	4501                	li	a0,0
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	14c080e7          	jalr	332(ra) # 80002c0a <argstr>
    return -1;
    80005ac6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ac8:	0c054a63          	bltz	a0,80005b9c <sys_exec+0xfa>
    80005acc:	e3840593          	addi	a1,s0,-456
    80005ad0:	4505                	li	a0,1
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	116080e7          	jalr	278(ra) # 80002be8 <argaddr>
    80005ada:	0c054163          	bltz	a0,80005b9c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ade:	10000613          	li	a2,256
    80005ae2:	4581                	li	a1,0
    80005ae4:	e4040513          	addi	a0,s0,-448
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	2aa080e7          	jalr	682(ra) # 80000d92 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005af0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005af4:	89a6                	mv	s3,s1
    80005af6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005af8:	02000a13          	li	s4,32
    80005afc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b00:	00391513          	slli	a0,s2,0x3
    80005b04:	e3040593          	addi	a1,s0,-464
    80005b08:	e3843783          	ld	a5,-456(s0)
    80005b0c:	953e                	add	a0,a0,a5
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	01e080e7          	jalr	30(ra) # 80002b2c <fetchaddr>
    80005b16:	02054a63          	bltz	a0,80005b4a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b1a:	e3043783          	ld	a5,-464(s0)
    80005b1e:	c3b9                	beqz	a5,80005b64 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b20:	ffffb097          	auipc	ra,0xffffb
    80005b24:	086080e7          	jalr	134(ra) # 80000ba6 <kalloc>
    80005b28:	85aa                	mv	a1,a0
    80005b2a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b2e:	cd11                	beqz	a0,80005b4a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b30:	6605                	lui	a2,0x1
    80005b32:	e3043503          	ld	a0,-464(s0)
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	048080e7          	jalr	72(ra) # 80002b7e <fetchstr>
    80005b3e:	00054663          	bltz	a0,80005b4a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b42:	0905                	addi	s2,s2,1
    80005b44:	09a1                	addi	s3,s3,8
    80005b46:	fb491be3          	bne	s2,s4,80005afc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4a:	10048913          	addi	s2,s1,256
    80005b4e:	6088                	ld	a0,0(s1)
    80005b50:	c529                	beqz	a0,80005b9a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b52:	ffffb097          	auipc	ra,0xffffb
    80005b56:	f58080e7          	jalr	-168(ra) # 80000aaa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5a:	04a1                	addi	s1,s1,8
    80005b5c:	ff2499e3          	bne	s1,s2,80005b4e <sys_exec+0xac>
  return -1;
    80005b60:	597d                	li	s2,-1
    80005b62:	a82d                	j	80005b9c <sys_exec+0xfa>
      argv[i] = 0;
    80005b64:	0a8e                	slli	s5,s5,0x3
    80005b66:	fc040793          	addi	a5,s0,-64
    80005b6a:	9abe                	add	s5,s5,a5
    80005b6c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b70:	e4040593          	addi	a1,s0,-448
    80005b74:	f4040513          	addi	a0,s0,-192
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	194080e7          	jalr	404(ra) # 80004d0c <exec>
    80005b80:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b82:	10048993          	addi	s3,s1,256
    80005b86:	6088                	ld	a0,0(s1)
    80005b88:	c911                	beqz	a0,80005b9c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b8a:	ffffb097          	auipc	ra,0xffffb
    80005b8e:	f20080e7          	jalr	-224(ra) # 80000aaa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b92:	04a1                	addi	s1,s1,8
    80005b94:	ff3499e3          	bne	s1,s3,80005b86 <sys_exec+0xe4>
    80005b98:	a011                	j	80005b9c <sys_exec+0xfa>
  return -1;
    80005b9a:	597d                	li	s2,-1
}
    80005b9c:	854a                	mv	a0,s2
    80005b9e:	60be                	ld	ra,456(sp)
    80005ba0:	641e                	ld	s0,448(sp)
    80005ba2:	74fa                	ld	s1,440(sp)
    80005ba4:	795a                	ld	s2,432(sp)
    80005ba6:	79ba                	ld	s3,424(sp)
    80005ba8:	7a1a                	ld	s4,416(sp)
    80005baa:	6afa                	ld	s5,408(sp)
    80005bac:	6179                	addi	sp,sp,464
    80005bae:	8082                	ret

0000000080005bb0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bb0:	7139                	addi	sp,sp,-64
    80005bb2:	fc06                	sd	ra,56(sp)
    80005bb4:	f822                	sd	s0,48(sp)
    80005bb6:	f426                	sd	s1,40(sp)
    80005bb8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bba:	ffffc097          	auipc	ra,0xffffc
    80005bbe:	eaa080e7          	jalr	-342(ra) # 80001a64 <myproc>
    80005bc2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bc4:	fd840593          	addi	a1,s0,-40
    80005bc8:	4501                	li	a0,0
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	01e080e7          	jalr	30(ra) # 80002be8 <argaddr>
    return -1;
    80005bd2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bd4:	0e054063          	bltz	a0,80005cb4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bd8:	fc840593          	addi	a1,s0,-56
    80005bdc:	fd040513          	addi	a0,s0,-48
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	dd2080e7          	jalr	-558(ra) # 800049b2 <pipealloc>
    return -1;
    80005be8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bea:	0c054563          	bltz	a0,80005cb4 <sys_pipe+0x104>
  fd0 = -1;
    80005bee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bf2:	fd043503          	ld	a0,-48(s0)
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	508080e7          	jalr	1288(ra) # 800050fe <fdalloc>
    80005bfe:	fca42223          	sw	a0,-60(s0)
    80005c02:	08054c63          	bltz	a0,80005c9a <sys_pipe+0xea>
    80005c06:	fc843503          	ld	a0,-56(s0)
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	4f4080e7          	jalr	1268(ra) # 800050fe <fdalloc>
    80005c12:	fca42023          	sw	a0,-64(s0)
    80005c16:	06054863          	bltz	a0,80005c86 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1a:	4691                	li	a3,4
    80005c1c:	fc440613          	addi	a2,s0,-60
    80005c20:	fd843583          	ld	a1,-40(s0)
    80005c24:	68a8                	ld	a0,80(s1)
    80005c26:	ffffc097          	auipc	ra,0xffffc
    80005c2a:	b32080e7          	jalr	-1230(ra) # 80001758 <copyout>
    80005c2e:	02054063          	bltz	a0,80005c4e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c32:	4691                	li	a3,4
    80005c34:	fc040613          	addi	a2,s0,-64
    80005c38:	fd843583          	ld	a1,-40(s0)
    80005c3c:	0591                	addi	a1,a1,4
    80005c3e:	68a8                	ld	a0,80(s1)
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	b18080e7          	jalr	-1256(ra) # 80001758 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c48:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4a:	06055563          	bgez	a0,80005cb4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c4e:	fc442783          	lw	a5,-60(s0)
    80005c52:	07e9                	addi	a5,a5,26
    80005c54:	078e                	slli	a5,a5,0x3
    80005c56:	97a6                	add	a5,a5,s1
    80005c58:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c5c:	fc042503          	lw	a0,-64(s0)
    80005c60:	0569                	addi	a0,a0,26
    80005c62:	050e                	slli	a0,a0,0x3
    80005c64:	9526                	add	a0,a0,s1
    80005c66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c6a:	fd043503          	ld	a0,-48(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	9ee080e7          	jalr	-1554(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005c76:	fc843503          	ld	a0,-56(s0)
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	9e2080e7          	jalr	-1566(ra) # 8000465c <fileclose>
    return -1;
    80005c82:	57fd                	li	a5,-1
    80005c84:	a805                	j	80005cb4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c86:	fc442783          	lw	a5,-60(s0)
    80005c8a:	0007c863          	bltz	a5,80005c9a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c8e:	01a78513          	addi	a0,a5,26
    80005c92:	050e                	slli	a0,a0,0x3
    80005c94:	9526                	add	a0,a0,s1
    80005c96:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c9a:	fd043503          	ld	a0,-48(s0)
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	9be080e7          	jalr	-1602(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005ca6:	fc843503          	ld	a0,-56(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	9b2080e7          	jalr	-1614(ra) # 8000465c <fileclose>
    return -1;
    80005cb2:	57fd                	li	a5,-1
}
    80005cb4:	853e                	mv	a0,a5
    80005cb6:	70e2                	ld	ra,56(sp)
    80005cb8:	7442                	ld	s0,48(sp)
    80005cba:	74a2                	ld	s1,40(sp)
    80005cbc:	6121                	addi	sp,sp,64
    80005cbe:	8082                	ret

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	cf9fc0ef          	jal	ra,800029f8 <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	710c                	ld	a1,32(a0)
    80005d5c:	7510                	ld	a2,40(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	ca0080e7          	jalr	-864(ra) # 80001a38 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	c68080e7          	jalr	-920(ra) # 80001a38 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	c40080e7          	jalr	-960(ra) # 80001a38 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cc63          	blt	a5,a0,80005e78 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e24:	0001e797          	auipc	a5,0x1e
    80005e28:	1dc78793          	addi	a5,a5,476 # 80024000 <disk>
    80005e2c:	00a78733          	add	a4,a5,a0
    80005e30:	6789                	lui	a5,0x2
    80005e32:	97ba                	add	a5,a5,a4
    80005e34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e38:	eba1                	bnez	a5,80005e88 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e3a:	00451713          	slli	a4,a0,0x4
    80005e3e:	00020797          	auipc	a5,0x20
    80005e42:	1c27b783          	ld	a5,450(a5) # 80026000 <disk+0x2000>
    80005e46:	97ba                	add	a5,a5,a4
    80005e48:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e4c:	0001e797          	auipc	a5,0x1e
    80005e50:	1b478793          	addi	a5,a5,436 # 80024000 <disk>
    80005e54:	97aa                	add	a5,a5,a0
    80005e56:	6509                	lui	a0,0x2
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	4785                	li	a5,1
    80005e5c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e60:	00020517          	auipc	a0,0x20
    80005e64:	1b850513          	addi	a0,a0,440 # 80026018 <disk+0x2018>
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	5e8080e7          	jalr	1512(ra) # 80002450 <wakeup>
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	93050513          	addi	a0,a0,-1744 # 800087a8 <syscalls+0x340>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	778080e7          	jalr	1912(ra) # 800005f8 <panic>
    panic("virtio_disk_intr 2");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	93850513          	addi	a0,a0,-1736 # 800087c0 <syscalls+0x358>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	768080e7          	jalr	1896(ra) # 800005f8 <panic>

0000000080005e98 <virtio_disk_init>:
{
    80005e98:	1101                	addi	sp,sp,-32
    80005e9a:	ec06                	sd	ra,24(sp)
    80005e9c:	e822                	sd	s0,16(sp)
    80005e9e:	e426                	sd	s1,8(sp)
    80005ea0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea2:	00003597          	auipc	a1,0x3
    80005ea6:	93658593          	addi	a1,a1,-1738 # 800087d8 <syscalls+0x370>
    80005eaa:	00020517          	auipc	a0,0x20
    80005eae:	1fe50513          	addi	a0,a0,510 # 800260a8 <disk+0x20a8>
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	d54080e7          	jalr	-684(ra) # 80000c06 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	4398                	lw	a4,0(a5)
    80005ec0:	2701                	sext.w	a4,a4
    80005ec2:	747277b7          	lui	a5,0x74727
    80005ec6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eca:	0ef71163          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	43dc                	lw	a5,4(a5)
    80005ed4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed6:	4705                	li	a4,1
    80005ed8:	0ce79a63          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	479c                	lw	a5,8(a5)
    80005ee2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ee4:	4709                	li	a4,2
    80005ee6:	0ce79363          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eea:	100017b7          	lui	a5,0x10001
    80005eee:	47d8                	lw	a4,12(a5)
    80005ef0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef2:	554d47b7          	lui	a5,0x554d4
    80005ef6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005efa:	0af71963          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	4705                	li	a4,1
    80005f04:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	470d                	li	a4,3
    80005f08:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f0a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f0c:	c7ffe737          	lui	a4,0xc7ffe
    80005f10:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005f14:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f16:	2701                	sext.w	a4,a4
    80005f18:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1a:	472d                	li	a4,11
    80005f1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	473d                	li	a4,15
    80005f20:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f22:	6705                	lui	a4,0x1
    80005f24:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f26:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2a:	5bdc                	lw	a5,52(a5)
    80005f2c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f2e:	c7d9                	beqz	a5,80005fbc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f30:	471d                	li	a4,7
    80005f32:	08f77d63          	bgeu	a4,a5,80005fcc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f36:	100014b7          	lui	s1,0x10001
    80005f3a:	47a1                	li	a5,8
    80005f3c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f3e:	6609                	lui	a2,0x2
    80005f40:	4581                	li	a1,0
    80005f42:	0001e517          	auipc	a0,0x1e
    80005f46:	0be50513          	addi	a0,a0,190 # 80024000 <disk>
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	e48080e7          	jalr	-440(ra) # 80000d92 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f52:	0001e717          	auipc	a4,0x1e
    80005f56:	0ae70713          	addi	a4,a4,174 # 80024000 <disk>
    80005f5a:	00c75793          	srli	a5,a4,0xc
    80005f5e:	2781                	sext.w	a5,a5
    80005f60:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f62:	00020797          	auipc	a5,0x20
    80005f66:	09e78793          	addi	a5,a5,158 # 80026000 <disk+0x2000>
    80005f6a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f6c:	0001e717          	auipc	a4,0x1e
    80005f70:	11470713          	addi	a4,a4,276 # 80024080 <disk+0x80>
    80005f74:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f76:	0001f717          	auipc	a4,0x1f
    80005f7a:	08a70713          	addi	a4,a4,138 # 80025000 <disk+0x1000>
    80005f7e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f80:	4705                	li	a4,1
    80005f82:	00e78c23          	sb	a4,24(a5)
    80005f86:	00e78ca3          	sb	a4,25(a5)
    80005f8a:	00e78d23          	sb	a4,26(a5)
    80005f8e:	00e78da3          	sb	a4,27(a5)
    80005f92:	00e78e23          	sb	a4,28(a5)
    80005f96:	00e78ea3          	sb	a4,29(a5)
    80005f9a:	00e78f23          	sb	a4,30(a5)
    80005f9e:	00e78fa3          	sb	a4,31(a5)
}
    80005fa2:	60e2                	ld	ra,24(sp)
    80005fa4:	6442                	ld	s0,16(sp)
    80005fa6:	64a2                	ld	s1,8(sp)
    80005fa8:	6105                	addi	sp,sp,32
    80005faa:	8082                	ret
    panic("could not find virtio disk");
    80005fac:	00003517          	auipc	a0,0x3
    80005fb0:	83c50513          	addi	a0,a0,-1988 # 800087e8 <syscalls+0x380>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	644080e7          	jalr	1604(ra) # 800005f8 <panic>
    panic("virtio disk has no queue 0");
    80005fbc:	00003517          	auipc	a0,0x3
    80005fc0:	84c50513          	addi	a0,a0,-1972 # 80008808 <syscalls+0x3a0>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	634080e7          	jalr	1588(ra) # 800005f8 <panic>
    panic("virtio disk max queue too short");
    80005fcc:	00003517          	auipc	a0,0x3
    80005fd0:	85c50513          	addi	a0,a0,-1956 # 80008828 <syscalls+0x3c0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	624080e7          	jalr	1572(ra) # 800005f8 <panic>

0000000080005fdc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fdc:	7119                	addi	sp,sp,-128
    80005fde:	fc86                	sd	ra,120(sp)
    80005fe0:	f8a2                	sd	s0,112(sp)
    80005fe2:	f4a6                	sd	s1,104(sp)
    80005fe4:	f0ca                	sd	s2,96(sp)
    80005fe6:	ecce                	sd	s3,88(sp)
    80005fe8:	e8d2                	sd	s4,80(sp)
    80005fea:	e4d6                	sd	s5,72(sp)
    80005fec:	e0da                	sd	s6,64(sp)
    80005fee:	fc5e                	sd	s7,56(sp)
    80005ff0:	f862                	sd	s8,48(sp)
    80005ff2:	f466                	sd	s9,40(sp)
    80005ff4:	f06a                	sd	s10,32(sp)
    80005ff6:	0100                	addi	s0,sp,128
    80005ff8:	892a                	mv	s2,a0
    80005ffa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ffc:	00c52c83          	lw	s9,12(a0)
    80006000:	001c9c9b          	slliw	s9,s9,0x1
    80006004:	1c82                	slli	s9,s9,0x20
    80006006:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000600a:	00020517          	auipc	a0,0x20
    8000600e:	09e50513          	addi	a0,a0,158 # 800260a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	c84080e7          	jalr	-892(ra) # 80000c96 <acquire>
  for(int i = 0; i < 3; i++){
    8000601a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000601c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000601e:	0001eb97          	auipc	s7,0x1e
    80006022:	fe2b8b93          	addi	s7,s7,-30 # 80024000 <disk>
    80006026:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006028:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000602a:	8a4e                	mv	s4,s3
    8000602c:	a051                	j	800060b0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000602e:	00fb86b3          	add	a3,s7,a5
    80006032:	96da                	add	a3,a3,s6
    80006034:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006038:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000603a:	0207c563          	bltz	a5,80006064 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000603e:	2485                	addiw	s1,s1,1
    80006040:	0711                	addi	a4,a4,4
    80006042:	23548d63          	beq	s1,s5,8000627c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006046:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006048:	00020697          	auipc	a3,0x20
    8000604c:	fd068693          	addi	a3,a3,-48 # 80026018 <disk+0x2018>
    80006050:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006052:	0006c583          	lbu	a1,0(a3)
    80006056:	fde1                	bnez	a1,8000602e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006058:	2785                	addiw	a5,a5,1
    8000605a:	0685                	addi	a3,a3,1
    8000605c:	ff879be3          	bne	a5,s8,80006052 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006060:	57fd                	li	a5,-1
    80006062:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006064:	02905a63          	blez	s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006068:	f9042503          	lw	a0,-112(s0)
    8000606c:	00000097          	auipc	ra,0x0
    80006070:	daa080e7          	jalr	-598(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006074:	4785                	li	a5,1
    80006076:	0297d163          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000607a:	f9442503          	lw	a0,-108(s0)
    8000607e:	00000097          	auipc	ra,0x0
    80006082:	d98080e7          	jalr	-616(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006086:	4789                	li	a5,2
    80006088:	0097d863          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000608c:	f9842503          	lw	a0,-104(s0)
    80006090:	00000097          	auipc	ra,0x0
    80006094:	d86080e7          	jalr	-634(ra) # 80005e16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006098:	00020597          	auipc	a1,0x20
    8000609c:	01058593          	addi	a1,a1,16 # 800260a8 <disk+0x20a8>
    800060a0:	00020517          	auipc	a0,0x20
    800060a4:	f7850513          	addi	a0,a0,-136 # 80026018 <disk+0x2018>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	222080e7          	jalr	546(ra) # 800022ca <sleep>
  for(int i = 0; i < 3; i++){
    800060b0:	f9040713          	addi	a4,s0,-112
    800060b4:	84ce                	mv	s1,s3
    800060b6:	bf41                	j	80006046 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060b8:	4785                	li	a5,1
    800060ba:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060be:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060c2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060c6:	f9042983          	lw	s3,-112(s0)
    800060ca:	00499493          	slli	s1,s3,0x4
    800060ce:	00020a17          	auipc	s4,0x20
    800060d2:	f32a0a13          	addi	s4,s4,-206 # 80026000 <disk+0x2000>
    800060d6:	000a3a83          	ld	s5,0(s4)
    800060da:	9aa6                	add	s5,s5,s1
    800060dc:	f8040513          	addi	a0,s0,-128
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	086080e7          	jalr	134(ra) # 80001166 <kvmpa>
    800060e8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060ec:	000a3783          	ld	a5,0(s4)
    800060f0:	97a6                	add	a5,a5,s1
    800060f2:	4741                	li	a4,16
    800060f4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f6:	000a3783          	ld	a5,0(s4)
    800060fa:	97a6                	add	a5,a5,s1
    800060fc:	4705                	li	a4,1
    800060fe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006102:	f9442703          	lw	a4,-108(s0)
    80006106:	000a3783          	ld	a5,0(s4)
    8000610a:	97a6                	add	a5,a5,s1
    8000610c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0712                	slli	a4,a4,0x4
    80006112:	000a3783          	ld	a5,0(s4)
    80006116:	97ba                	add	a5,a5,a4
    80006118:	05890693          	addi	a3,s2,88
    8000611c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000611e:	000a3783          	ld	a5,0(s4)
    80006122:	97ba                	add	a5,a5,a4
    80006124:	40000693          	li	a3,1024
    80006128:	c794                	sw	a3,8(a5)
  if(write)
    8000612a:	100d0a63          	beqz	s10,8000623e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000612e:	00020797          	auipc	a5,0x20
    80006132:	ed27b783          	ld	a5,-302(a5) # 80026000 <disk+0x2000>
    80006136:	97ba                	add	a5,a5,a4
    80006138:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000613c:	0001e517          	auipc	a0,0x1e
    80006140:	ec450513          	addi	a0,a0,-316 # 80024000 <disk>
    80006144:	00020797          	auipc	a5,0x20
    80006148:	ebc78793          	addi	a5,a5,-324 # 80026000 <disk+0x2000>
    8000614c:	6394                	ld	a3,0(a5)
    8000614e:	96ba                	add	a3,a3,a4
    80006150:	00c6d603          	lhu	a2,12(a3)
    80006154:	00166613          	ori	a2,a2,1
    80006158:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000615c:	f9842683          	lw	a3,-104(s0)
    80006160:	6390                	ld	a2,0(a5)
    80006162:	9732                	add	a4,a4,a2
    80006164:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006168:	20098613          	addi	a2,s3,512
    8000616c:	0612                	slli	a2,a2,0x4
    8000616e:	962a                	add	a2,a2,a0
    80006170:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006174:	00469713          	slli	a4,a3,0x4
    80006178:	6394                	ld	a3,0(a5)
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	6589                	lui	a1,0x2
    8000617e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006182:	94ae                	add	s1,s1,a1
    80006184:	94aa                	add	s1,s1,a0
    80006186:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006188:	6394                	ld	a3,0(a5)
    8000618a:	96ba                	add	a3,a3,a4
    8000618c:	4585                	li	a1,1
    8000618e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006190:	6394                	ld	a3,0(a5)
    80006192:	96ba                	add	a3,a3,a4
    80006194:	4509                	li	a0,2
    80006196:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000619a:	6394                	ld	a3,0(a5)
    8000619c:	9736                	add	a4,a4,a3
    8000619e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061a2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061a6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061aa:	6794                	ld	a3,8(a5)
    800061ac:	0026d703          	lhu	a4,2(a3)
    800061b0:	8b1d                	andi	a4,a4,7
    800061b2:	2709                	addiw	a4,a4,2
    800061b4:	0706                	slli	a4,a4,0x1
    800061b6:	9736                	add	a4,a4,a3
    800061b8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061bc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061c0:	6798                	ld	a4,8(a5)
    800061c2:	00275783          	lhu	a5,2(a4)
    800061c6:	2785                	addiw	a5,a5,1
    800061c8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061cc:	100017b7          	lui	a5,0x10001
    800061d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061d4:	00492703          	lw	a4,4(s2)
    800061d8:	4785                	li	a5,1
    800061da:	02f71163          	bne	a4,a5,800061fc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061de:	00020997          	auipc	s3,0x20
    800061e2:	eca98993          	addi	s3,s3,-310 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061e8:	85ce                	mv	a1,s3
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffc097          	auipc	ra,0xffffc
    800061f0:	0de080e7          	jalr	222(ra) # 800022ca <sleep>
  while(b->disk == 1) {
    800061f4:	00492783          	lw	a5,4(s2)
    800061f8:	fe9788e3          	beq	a5,s1,800061e8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061fc:	f9042483          	lw	s1,-112(s0)
    80006200:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006204:	00479713          	slli	a4,a5,0x4
    80006208:	0001e797          	auipc	a5,0x1e
    8000620c:	df878793          	addi	a5,a5,-520 # 80024000 <disk>
    80006210:	97ba                	add	a5,a5,a4
    80006212:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006216:	00020917          	auipc	s2,0x20
    8000621a:	dea90913          	addi	s2,s2,-534 # 80026000 <disk+0x2000>
    free_desc(i);
    8000621e:	8526                	mv	a0,s1
    80006220:	00000097          	auipc	ra,0x0
    80006224:	bf6080e7          	jalr	-1034(ra) # 80005e16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006228:	0492                	slli	s1,s1,0x4
    8000622a:	00093783          	ld	a5,0(s2)
    8000622e:	94be                	add	s1,s1,a5
    80006230:	00c4d783          	lhu	a5,12(s1)
    80006234:	8b85                	andi	a5,a5,1
    80006236:	cf89                	beqz	a5,80006250 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006238:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000623c:	b7cd                	j	8000621e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623e:	00020797          	auipc	a5,0x20
    80006242:	dc27b783          	ld	a5,-574(a5) # 80026000 <disk+0x2000>
    80006246:	97ba                	add	a5,a5,a4
    80006248:	4689                	li	a3,2
    8000624a:	00d79623          	sh	a3,12(a5)
    8000624e:	b5fd                	j	8000613c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006250:	00020517          	auipc	a0,0x20
    80006254:	e5850513          	addi	a0,a0,-424 # 800260a8 <disk+0x20a8>
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	af2080e7          	jalr	-1294(ra) # 80000d4a <release>
}
    80006260:	70e6                	ld	ra,120(sp)
    80006262:	7446                	ld	s0,112(sp)
    80006264:	74a6                	ld	s1,104(sp)
    80006266:	7906                	ld	s2,96(sp)
    80006268:	69e6                	ld	s3,88(sp)
    8000626a:	6a46                	ld	s4,80(sp)
    8000626c:	6aa6                	ld	s5,72(sp)
    8000626e:	6b06                	ld	s6,64(sp)
    80006270:	7be2                	ld	s7,56(sp)
    80006272:	7c42                	ld	s8,48(sp)
    80006274:	7ca2                	ld	s9,40(sp)
    80006276:	7d02                	ld	s10,32(sp)
    80006278:	6109                	addi	sp,sp,128
    8000627a:	8082                	ret
  if(write)
    8000627c:	e20d1ee3          	bnez	s10,800060b8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006280:	f8042023          	sw	zero,-128(s0)
    80006284:	bd2d                	j	800060be <virtio_disk_rw+0xe2>

0000000080006286 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006286:	1101                	addi	sp,sp,-32
    80006288:	ec06                	sd	ra,24(sp)
    8000628a:	e822                	sd	s0,16(sp)
    8000628c:	e426                	sd	s1,8(sp)
    8000628e:	e04a                	sd	s2,0(sp)
    80006290:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006292:	00020517          	auipc	a0,0x20
    80006296:	e1650513          	addi	a0,a0,-490 # 800260a8 <disk+0x20a8>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	9fc080e7          	jalr	-1540(ra) # 80000c96 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062a2:	00020717          	auipc	a4,0x20
    800062a6:	d5e70713          	addi	a4,a4,-674 # 80026000 <disk+0x2000>
    800062aa:	02075783          	lhu	a5,32(a4)
    800062ae:	6b18                	ld	a4,16(a4)
    800062b0:	00275683          	lhu	a3,2(a4)
    800062b4:	8ebd                	xor	a3,a3,a5
    800062b6:	8a9d                	andi	a3,a3,7
    800062b8:	cab9                	beqz	a3,8000630e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062ba:	0001e917          	auipc	s2,0x1e
    800062be:	d4690913          	addi	s2,s2,-698 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062c2:	00020497          	auipc	s1,0x20
    800062c6:	d3e48493          	addi	s1,s1,-706 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ca:	078e                	slli	a5,a5,0x3
    800062cc:	97ba                	add	a5,a5,a4
    800062ce:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062d0:	20078713          	addi	a4,a5,512
    800062d4:	0712                	slli	a4,a4,0x4
    800062d6:	974a                	add	a4,a4,s2
    800062d8:	03074703          	lbu	a4,48(a4)
    800062dc:	ef21                	bnez	a4,80006334 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062de:	20078793          	addi	a5,a5,512
    800062e2:	0792                	slli	a5,a5,0x4
    800062e4:	97ca                	add	a5,a5,s2
    800062e6:	7798                	ld	a4,40(a5)
    800062e8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062ec:	7788                	ld	a0,40(a5)
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	162080e7          	jalr	354(ra) # 80002450 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062f6:	0204d783          	lhu	a5,32(s1)
    800062fa:	2785                	addiw	a5,a5,1
    800062fc:	8b9d                	andi	a5,a5,7
    800062fe:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006302:	6898                	ld	a4,16(s1)
    80006304:	00275683          	lhu	a3,2(a4)
    80006308:	8a9d                	andi	a3,a3,7
    8000630a:	fcf690e3          	bne	a3,a5,800062ca <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000630e:	10001737          	lui	a4,0x10001
    80006312:	533c                	lw	a5,96(a4)
    80006314:	8b8d                	andi	a5,a5,3
    80006316:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006318:	00020517          	auipc	a0,0x20
    8000631c:	d9050513          	addi	a0,a0,-624 # 800260a8 <disk+0x20a8>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	a2a080e7          	jalr	-1494(ra) # 80000d4a <release>
}
    80006328:	60e2                	ld	ra,24(sp)
    8000632a:	6442                	ld	s0,16(sp)
    8000632c:	64a2                	ld	s1,8(sp)
    8000632e:	6902                	ld	s2,0(sp)
    80006330:	6105                	addi	sp,sp,32
    80006332:	8082                	ret
      panic("virtio_disk_intr status");
    80006334:	00002517          	auipc	a0,0x2
    80006338:	51450513          	addi	a0,a0,1300 # 80008848 <syscalls+0x3e0>
    8000633c:	ffffa097          	auipc	ra,0xffffa
    80006340:	2bc080e7          	jalr	700(ra) # 800005f8 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
