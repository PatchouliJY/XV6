
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
    80000060:	c2478793          	addi	a5,a5,-988 # 80005c80 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	3da080e7          	jalr	986(ra) # 80002500 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	86a080e7          	jalr	-1942(ra) # 80001a38 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	06a080e7          	jalr	106(ra) # 80002248 <sleep>
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
    8000021e:	290080e7          	jalr	656(ra) # 800024aa <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	25a080e7          	jalr	602(ra) # 80002556 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	f7e080e7          	jalr	-130(ra) # 800023ce <wakeup>
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
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
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
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
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

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b18080e7          	jalr	-1256(ra) # 800023ce <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8f8080e7          	jalr	-1800(ra) # 80002248 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e72080e7          	jalr	-398(ra) # 80001a1c <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	e40080e7          	jalr	-448(ra) # 80001a1c <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	e34080e7          	jalr	-460(ra) # 80001a1c <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	e1c080e7          	jalr	-484(ra) # 80001a1c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ddc080e7          	jalr	-548(ra) # 80001a1c <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	db0080e7          	jalr	-592(ra) # 80001a1c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	b46080e7          	jalr	-1210(ra) # 80001a0c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	b2a080e7          	jalr	-1238(ra) # 80001a0c <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	792080e7          	jalr	1938(ra) # 80002696 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	db4080e7          	jalr	-588(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	054080e7          	jalr	84(ra) # 80001f68 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	32e080e7          	jalr	814(ra) # 80001292 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	9c8080e7          	jalr	-1592(ra) # 8000193c <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	6f2080e7          	jalr	1778(ra) # 8000266e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	712080e7          	jalr	1810(ra) # 80002696 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	d1e080e7          	jalr	-738(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d2c080e7          	jalr	-724(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	ec2080e7          	jalr	-318(ra) # 80002e5e <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	552080e7          	jalr	1362(ra) # 800034f6 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	4f0080e7          	jalr	1264(ra) # 8000449c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	e14080e7          	jalr	-492(ra) # 80005dc8 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	d46080e7          	jalr	-698(ra) # 80001d02 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000109e:	1101                	addi	sp,sp,-32
    800010a0:	ec06                	sd	ra,24(sp)
    800010a2:	e822                	sd	s0,16(sp)
    800010a4:	e426                	sd	s1,8(sp)
    800010a6:	1000                	addi	s0,sp,32
    800010a8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010aa:	1552                	slli	a0,a0,0x34
    800010ac:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010b0:	4601                	li	a2,0
    800010b2:	00008517          	auipc	a0,0x8
    800010b6:	f5e53503          	ld	a0,-162(a0) # 80009010 <kernel_pagetable>
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	f3e080e7          	jalr	-194(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010c2:	cd09                	beqz	a0,800010dc <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010c4:	6108                	ld	a0,0(a0)
    800010c6:	00157793          	andi	a5,a0,1
    800010ca:	c38d                	beqz	a5,800010ec <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010cc:	8129                	srli	a0,a0,0xa
    800010ce:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010d0:	9526                	add	a0,a0,s1
    800010d2:	60e2                	ld	ra,24(sp)
    800010d4:	6442                	ld	s0,16(sp)
    800010d6:	64a2                	ld	s1,8(sp)
    800010d8:	6105                	addi	sp,sp,32
    800010da:	8082                	ret
    panic("kvmpa");
    800010dc:	00007517          	auipc	a0,0x7
    800010e0:	ffc50513          	addi	a0,a0,-4 # 800080d8 <digits+0x98>
    800010e4:	fffff097          	auipc	ra,0xfffff
    800010e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>
    panic("kvmpa");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	fec50513          	addi	a0,a0,-20 # 800080d8 <digits+0x98>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>

00000000800010fc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010fc:	715d                	addi	sp,sp,-80
    800010fe:	e486                	sd	ra,72(sp)
    80001100:	e0a2                	sd	s0,64(sp)
    80001102:	fc26                	sd	s1,56(sp)
    80001104:	f84a                	sd	s2,48(sp)
    80001106:	f44e                	sd	s3,40(sp)
    80001108:	f052                	sd	s4,32(sp)
    8000110a:	ec56                	sd	s5,24(sp)
    8000110c:	e85a                	sd	s6,16(sp)
    8000110e:	e45e                	sd	s7,8(sp)
    80001110:	0880                	addi	s0,sp,80
    80001112:	8aaa                	mv	s5,a0
    80001114:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001116:	777d                	lui	a4,0xfffff
    80001118:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111c:	167d                	addi	a2,a2,-1
    8000111e:	00b609b3          	add	s3,a2,a1
    80001122:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001126:	893e                	mv	s2,a5
    80001128:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112c:	6b85                	lui	s7,0x1
    8000112e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001132:	4605                	li	a2,1
    80001134:	85ca                	mv	a1,s2
    80001136:	8556                	mv	a0,s5
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	ec0080e7          	jalr	-320(ra) # 80000ff8 <walk>
    80001140:	c51d                	beqz	a0,8000116e <mappages+0x72>
    if(*pte & PTE_V)
    80001142:	611c                	ld	a5,0(a0)
    80001144:	8b85                	andi	a5,a5,1
    80001146:	ef81                	bnez	a5,8000115e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001148:	80b1                	srli	s1,s1,0xc
    8000114a:	04aa                	slli	s1,s1,0xa
    8000114c:	0164e4b3          	or	s1,s1,s6
    80001150:	0014e493          	ori	s1,s1,1
    80001154:	e104                	sd	s1,0(a0)
    if(a == last)
    80001156:	03390863          	beq	s2,s3,80001186 <mappages+0x8a>
    a += PGSIZE;
    8000115a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115c:	bfc9                	j	8000112e <mappages+0x32>
      panic("remap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f8250513          	addi	a0,a0,-126 # 800080e0 <digits+0xa0>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3e2080e7          	jalr	994(ra) # 80000548 <panic>
      return -1;
    8000116e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001170:	60a6                	ld	ra,72(sp)
    80001172:	6406                	ld	s0,64(sp)
    80001174:	74e2                	ld	s1,56(sp)
    80001176:	7942                	ld	s2,48(sp)
    80001178:	79a2                	ld	s3,40(sp)
    8000117a:	7a02                	ld	s4,32(sp)
    8000117c:	6ae2                	ld	s5,24(sp)
    8000117e:	6b42                	ld	s6,16(sp)
    80001180:	6ba2                	ld	s7,8(sp)
    80001182:	6161                	addi	sp,sp,80
    80001184:	8082                	ret
  return 0;
    80001186:	4501                	li	a0,0
    80001188:	b7e5                	j	80001170 <mappages+0x74>

000000008000118a <walkaddr>:
  if(va >= MAXVA)
    8000118a:	57fd                	li	a5,-1
    8000118c:	83e9                	srli	a5,a5,0x1a
    8000118e:	00b7f463          	bgeu	a5,a1,80001196 <walkaddr+0xc>
    return 0;
    80001192:	4501                	li	a0,0
}
    80001194:	8082                	ret
{
    80001196:	7179                	addi	sp,sp,-48
    80001198:	f406                	sd	ra,40(sp)
    8000119a:	f022                	sd	s0,32(sp)
    8000119c:	ec26                	sd	s1,24(sp)
    8000119e:	e84a                	sd	s2,16(sp)
    800011a0:	e44e                	sd	s3,8(sp)
    800011a2:	e052                	sd	s4,0(sp)
    800011a4:	1800                	addi	s0,sp,48
    800011a6:	8a2a                	mv	s4,a0
    800011a8:	84ae                	mv	s1,a1
  pte = walk(pagetable, va, 0);
    800011aa:	4601                	li	a2,0
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	e4c080e7          	jalr	-436(ra) # 80000ff8 <walk>
    800011b4:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800011b6:	00001097          	auipc	ra,0x1
    800011ba:	882080e7          	jalr	-1918(ra) # 80001a38 <myproc>
    800011be:	89aa                	mv	s3,a0
  if(pte == 0 || ((*pte) & PTE_V) == 0) {
    800011c0:	00090663          	beqz	s2,800011cc <walkaddr+0x42>
    800011c4:	00093783          	ld	a5,0(s2)
    800011c8:	8b85                	andi	a5,a5,1
    800011ca:	e3ad                	bnez	a5,8000122c <walkaddr+0xa2>
    if (va < p->sz && va >= PGROUNDDOWN(p->trapframe->sp)) {
    800011cc:	0489b783          	ld	a5,72(s3) # 1048 <_entry-0x7fffefb8>
      return 0;
    800011d0:	4501                	li	a0,0
    if (va < p->sz && va >= PGROUNDDOWN(p->trapframe->sp)) {
    800011d2:	06f4f563          	bgeu	s1,a5,8000123c <walkaddr+0xb2>
    800011d6:	0589b783          	ld	a5,88(s3)
    800011da:	7b98                	ld	a4,48(a5)
    800011dc:	77fd                	lui	a5,0xfffff
    800011de:	8ff9                	and	a5,a5,a4
    800011e0:	04f4ee63          	bltu	s1,a5,8000123c <walkaddr+0xb2>
      char* mem = kalloc();
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	93c080e7          	jalr	-1732(ra) # 80000b20 <kalloc>
    800011ec:	892a                	mv	s2,a0
        return 0;
    800011ee:	4501                	li	a0,0
      if (mem == 0) {
    800011f0:	04090663          	beqz	s2,8000123c <walkaddr+0xb2>
        memset(mem, 0, PGSIZE);
    800011f4:	6605                	lui	a2,0x1
    800011f6:	4581                	li	a1,0
    800011f8:	854a                	mv	a0,s2
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	b12080e7          	jalr	-1262(ra) # 80000d0c <memset>
        va = PGROUNDDOWN(va);
    80001202:	75fd                	lui	a1,0xfffff
    80001204:	8ced                	and	s1,s1,a1
        if ((mappages(p->pagetable, va, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_U | PTE_X)) != 0) {
    80001206:	4779                	li	a4,30
    80001208:	86ca                	mv	a3,s2
    8000120a:	6605                	lui	a2,0x1
    8000120c:	85a6                	mv	a1,s1
    8000120e:	0509b503          	ld	a0,80(s3)
    80001212:	00000097          	auipc	ra,0x0
    80001216:	eea080e7          	jalr	-278(ra) # 800010fc <mappages>
    8000121a:	e90d                	bnez	a0,8000124c <walkaddr+0xc2>
        pte = walk(pagetable, va, 0);
    8000121c:	4601                	li	a2,0
    8000121e:	85a6                	mv	a1,s1
    80001220:	8552                	mv	a0,s4
    80001222:	00000097          	auipc	ra,0x0
    80001226:	dd6080e7          	jalr	-554(ra) # 80000ff8 <walk>
    8000122a:	892a                	mv	s2,a0
  if((*pte & PTE_U) == 0)
    8000122c:	00093783          	ld	a5,0(s2)
    80001230:	0107f513          	andi	a0,a5,16
    80001234:	c501                	beqz	a0,8000123c <walkaddr+0xb2>
  pa = PTE2PA(*pte);
    80001236:	00a7d513          	srli	a0,a5,0xa
    8000123a:	0532                	slli	a0,a0,0xc
}
    8000123c:	70a2                	ld	ra,40(sp)
    8000123e:	7402                	ld	s0,32(sp)
    80001240:	64e2                	ld	s1,24(sp)
    80001242:	6942                	ld	s2,16(sp)
    80001244:	69a2                	ld	s3,8(sp)
    80001246:	6a02                	ld	s4,0(sp)
    80001248:	6145                	addi	sp,sp,48
    8000124a:	8082                	ret
          kfree(mem);
    8000124c:	854a                	mv	a0,s2
    8000124e:	fffff097          	auipc	ra,0xfffff
    80001252:	7d6080e7          	jalr	2006(ra) # 80000a24 <kfree>
          return 0;
    80001256:	4501                	li	a0,0
    80001258:	b7d5                	j	8000123c <walkaddr+0xb2>

000000008000125a <kvmmap>:
{
    8000125a:	1141                	addi	sp,sp,-16
    8000125c:	e406                	sd	ra,8(sp)
    8000125e:	e022                	sd	s0,0(sp)
    80001260:	0800                	addi	s0,sp,16
    80001262:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001264:	86ae                	mv	a3,a1
    80001266:	85aa                	mv	a1,a0
    80001268:	00008517          	auipc	a0,0x8
    8000126c:	da853503          	ld	a0,-600(a0) # 80009010 <kernel_pagetable>
    80001270:	00000097          	auipc	ra,0x0
    80001274:	e8c080e7          	jalr	-372(ra) # 800010fc <mappages>
    80001278:	e509                	bnez	a0,80001282 <kvmmap+0x28>
}
    8000127a:	60a2                	ld	ra,8(sp)
    8000127c:	6402                	ld	s0,0(sp)
    8000127e:	0141                	addi	sp,sp,16
    80001280:	8082                	ret
    panic("kvmmap");
    80001282:	00007517          	auipc	a0,0x7
    80001286:	e6650513          	addi	a0,a0,-410 # 800080e8 <digits+0xa8>
    8000128a:	fffff097          	auipc	ra,0xfffff
    8000128e:	2be080e7          	jalr	702(ra) # 80000548 <panic>

0000000080001292 <kvminit>:
{
    80001292:	1101                	addi	sp,sp,-32
    80001294:	ec06                	sd	ra,24(sp)
    80001296:	e822                	sd	s0,16(sp)
    80001298:	e426                	sd	s1,8(sp)
    8000129a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	884080e7          	jalr	-1916(ra) # 80000b20 <kalloc>
    800012a4:	00008797          	auipc	a5,0x8
    800012a8:	d6a7b623          	sd	a0,-660(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012ac:	6605                	lui	a2,0x1
    800012ae:	4581                	li	a1,0
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	a5c080e7          	jalr	-1444(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012b8:	4699                	li	a3,6
    800012ba:	6605                	lui	a2,0x1
    800012bc:	100005b7          	lui	a1,0x10000
    800012c0:	10000537          	lui	a0,0x10000
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f96080e7          	jalr	-106(ra) # 8000125a <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012cc:	4699                	li	a3,6
    800012ce:	6605                	lui	a2,0x1
    800012d0:	100015b7          	lui	a1,0x10001
    800012d4:	10001537          	lui	a0,0x10001
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f82080e7          	jalr	-126(ra) # 8000125a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012e0:	4699                	li	a3,6
    800012e2:	6641                	lui	a2,0x10
    800012e4:	020005b7          	lui	a1,0x2000
    800012e8:	02000537          	lui	a0,0x2000
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	f6e080e7          	jalr	-146(ra) # 8000125a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f4:	4699                	li	a3,6
    800012f6:	00400637          	lui	a2,0x400
    800012fa:	0c0005b7          	lui	a1,0xc000
    800012fe:	0c000537          	lui	a0,0xc000
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f58080e7          	jalr	-168(ra) # 8000125a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000130a:	00007497          	auipc	s1,0x7
    8000130e:	cf648493          	addi	s1,s1,-778 # 80008000 <etext>
    80001312:	46a9                	li	a3,10
    80001314:	80007617          	auipc	a2,0x80007
    80001318:	cec60613          	addi	a2,a2,-788 # 8000 <_entry-0x7fff8000>
    8000131c:	4585                	li	a1,1
    8000131e:	05fe                	slli	a1,a1,0x1f
    80001320:	852e                	mv	a0,a1
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f38080e7          	jalr	-200(ra) # 8000125a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000132a:	4699                	li	a3,6
    8000132c:	4645                	li	a2,17
    8000132e:	066e                	slli	a2,a2,0x1b
    80001330:	8e05                	sub	a2,a2,s1
    80001332:	85a6                	mv	a1,s1
    80001334:	8526                	mv	a0,s1
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	f24080e7          	jalr	-220(ra) # 8000125a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000133e:	46a9                	li	a3,10
    80001340:	6605                	lui	a2,0x1
    80001342:	00006597          	auipc	a1,0x6
    80001346:	cbe58593          	addi	a1,a1,-834 # 80007000 <_trampoline>
    8000134a:	04000537          	lui	a0,0x4000
    8000134e:	157d                	addi	a0,a0,-1
    80001350:	0532                	slli	a0,a0,0xc
    80001352:	00000097          	auipc	ra,0x0
    80001356:	f08080e7          	jalr	-248(ra) # 8000125a <kvmmap>
}
    8000135a:	60e2                	ld	ra,24(sp)
    8000135c:	6442                	ld	s0,16(sp)
    8000135e:	64a2                	ld	s1,8(sp)
    80001360:	6105                	addi	sp,sp,32
    80001362:	8082                	ret

0000000080001364 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001364:	715d                	addi	sp,sp,-80
    80001366:	e486                	sd	ra,72(sp)
    80001368:	e0a2                	sd	s0,64(sp)
    8000136a:	fc26                	sd	s1,56(sp)
    8000136c:	f84a                	sd	s2,48(sp)
    8000136e:	f44e                	sd	s3,40(sp)
    80001370:	f052                	sd	s4,32(sp)
    80001372:	ec56                	sd	s5,24(sp)
    80001374:	e85a                	sd	s6,16(sp)
    80001376:	e45e                	sd	s7,8(sp)
    80001378:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000137a:	03459793          	slli	a5,a1,0x34
    8000137e:	e795                	bnez	a5,800013aa <uvmunmap+0x46>
    80001380:	8a2a                	mv	s4,a0
    80001382:	892e                	mv	s2,a1
    80001384:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001386:	0632                	slli	a2,a2,0xc
    80001388:	00b609b3          	add	s3,a2,a1
    if((*pte & PTE_V) == 0) {
      *pte = 0;
      continue;
    }
      // panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000138e:	6a85                	lui	s5,0x1
    80001390:	0535ec63          	bltu	a1,s3,800013e8 <uvmunmap+0x84>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001394:	60a6                	ld	ra,72(sp)
    80001396:	6406                	ld	s0,64(sp)
    80001398:	74e2                	ld	s1,56(sp)
    8000139a:	7942                	ld	s2,48(sp)
    8000139c:	79a2                	ld	s3,40(sp)
    8000139e:	7a02                	ld	s4,32(sp)
    800013a0:	6ae2                	ld	s5,24(sp)
    800013a2:	6b42                	ld	s6,16(sp)
    800013a4:	6ba2                	ld	s7,8(sp)
    800013a6:	6161                	addi	sp,sp,80
    800013a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800013aa:	00007517          	auipc	a0,0x7
    800013ae:	d4650513          	addi	a0,a0,-698 # 800080f0 <digits+0xb0>
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	196080e7          	jalr	406(ra) # 80000548 <panic>
      *pte = 0;
    800013ba:	00053023          	sd	zero,0(a0)
      continue;
    800013be:	a015                	j	800013e2 <uvmunmap+0x7e>
      panic("uvmunmap: not a leaf");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d4850513          	addi	a0,a0,-696 # 80008108 <digits+0xc8>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	180080e7          	jalr	384(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800013d2:	00c79513          	slli	a0,a5,0xc
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	64e080e7          	jalr	1614(ra) # 80000a24 <kfree>
    *pte = 0;
    800013de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e2:	9956                	add	s2,s2,s5
    800013e4:	fb3978e3          	bgeu	s2,s3,80001394 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e8:	4601                	li	a2,0
    800013ea:	85ca                	mv	a1,s2
    800013ec:	8552                	mv	a0,s4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	c0a080e7          	jalr	-1014(ra) # 80000ff8 <walk>
    800013f6:	84aa                	mv	s1,a0
    800013f8:	d56d                	beqz	a0,800013e2 <uvmunmap+0x7e>
    if((*pte & PTE_V) == 0) {
    800013fa:	611c                	ld	a5,0(a0)
    800013fc:	0017f713          	andi	a4,a5,1
    80001400:	df4d                	beqz	a4,800013ba <uvmunmap+0x56>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001402:	3ff7f713          	andi	a4,a5,1023
    80001406:	fb770de3          	beq	a4,s7,800013c0 <uvmunmap+0x5c>
    if(do_free){
    8000140a:	fc0b0ae3          	beqz	s6,800013de <uvmunmap+0x7a>
    8000140e:	b7c9                	j	800013d0 <uvmunmap+0x6c>

0000000080001410 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001410:	1101                	addi	sp,sp,-32
    80001412:	ec06                	sd	ra,24(sp)
    80001414:	e822                	sd	s0,16(sp)
    80001416:	e426                	sd	s1,8(sp)
    80001418:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	706080e7          	jalr	1798(ra) # 80000b20 <kalloc>
    80001422:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001424:	c519                	beqz	a0,80001432 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	8e2080e7          	jalr	-1822(ra) # 80000d0c <memset>
  return pagetable;
}
    80001432:	8526                	mv	a0,s1
    80001434:	60e2                	ld	ra,24(sp)
    80001436:	6442                	ld	s0,16(sp)
    80001438:	64a2                	ld	s1,8(sp)
    8000143a:	6105                	addi	sp,sp,32
    8000143c:	8082                	ret

000000008000143e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000143e:	7179                	addi	sp,sp,-48
    80001440:	f406                	sd	ra,40(sp)
    80001442:	f022                	sd	s0,32(sp)
    80001444:	ec26                	sd	s1,24(sp)
    80001446:	e84a                	sd	s2,16(sp)
    80001448:	e44e                	sd	s3,8(sp)
    8000144a:	e052                	sd	s4,0(sp)
    8000144c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000144e:	6785                	lui	a5,0x1
    80001450:	04f67863          	bgeu	a2,a5,800014a0 <uvminit+0x62>
    80001454:	8a2a                	mv	s4,a0
    80001456:	89ae                	mv	s3,a1
    80001458:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	6c6080e7          	jalr	1734(ra) # 80000b20 <kalloc>
    80001462:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001464:	6605                	lui	a2,0x1
    80001466:	4581                	li	a1,0
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	8a4080e7          	jalr	-1884(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001470:	4779                	li	a4,30
    80001472:	86ca                	mv	a3,s2
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	8552                	mv	a0,s4
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	c82080e7          	jalr	-894(ra) # 800010fc <mappages>
  memmove(mem, src, sz);
    80001482:	8626                	mv	a2,s1
    80001484:	85ce                	mv	a1,s3
    80001486:	854a                	mv	a0,s2
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	8e4080e7          	jalr	-1820(ra) # 80000d6c <memmove>
}
    80001490:	70a2                	ld	ra,40(sp)
    80001492:	7402                	ld	s0,32(sp)
    80001494:	64e2                	ld	s1,24(sp)
    80001496:	6942                	ld	s2,16(sp)
    80001498:	69a2                	ld	s3,8(sp)
    8000149a:	6a02                	ld	s4,0(sp)
    8000149c:	6145                	addi	sp,sp,48
    8000149e:	8082                	ret
    panic("inituvm: more than a page");
    800014a0:	00007517          	auipc	a0,0x7
    800014a4:	c8050513          	addi	a0,a0,-896 # 80008120 <digits+0xe0>
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	0a0080e7          	jalr	160(ra) # 80000548 <panic>

00000000800014b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014b0:	1101                	addi	sp,sp,-32
    800014b2:	ec06                	sd	ra,24(sp)
    800014b4:	e822                	sd	s0,16(sp)
    800014b6:	e426                	sd	s1,8(sp)
    800014b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014bc:	00b67d63          	bgeu	a2,a1,800014d6 <uvmdealloc+0x26>
    800014c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014c2:	6785                	lui	a5,0x1
    800014c4:	17fd                	addi	a5,a5,-1
    800014c6:	00f60733          	add	a4,a2,a5
    800014ca:	767d                	lui	a2,0xfffff
    800014cc:	8f71                	and	a4,a4,a2
    800014ce:	97ae                	add	a5,a5,a1
    800014d0:	8ff1                	and	a5,a5,a2
    800014d2:	00f76863          	bltu	a4,a5,800014e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014d6:	8526                	mv	a0,s1
    800014d8:	60e2                	ld	ra,24(sp)
    800014da:	6442                	ld	s0,16(sp)
    800014dc:	64a2                	ld	s1,8(sp)
    800014de:	6105                	addi	sp,sp,32
    800014e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014e2:	8f99                	sub	a5,a5,a4
    800014e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014e6:	4685                	li	a3,1
    800014e8:	0007861b          	sext.w	a2,a5
    800014ec:	85ba                	mv	a1,a4
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	e76080e7          	jalr	-394(ra) # 80001364 <uvmunmap>
    800014f6:	b7c5                	j	800014d6 <uvmdealloc+0x26>

00000000800014f8 <uvmalloc>:
  if(newsz < oldsz)
    800014f8:	0ab66163          	bltu	a2,a1,8000159a <uvmalloc+0xa2>
{
    800014fc:	7139                	addi	sp,sp,-64
    800014fe:	fc06                	sd	ra,56(sp)
    80001500:	f822                	sd	s0,48(sp)
    80001502:	f426                	sd	s1,40(sp)
    80001504:	f04a                	sd	s2,32(sp)
    80001506:	ec4e                	sd	s3,24(sp)
    80001508:	e852                	sd	s4,16(sp)
    8000150a:	e456                	sd	s5,8(sp)
    8000150c:	0080                	addi	s0,sp,64
    8000150e:	8aaa                	mv	s5,a0
    80001510:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001512:	6985                	lui	s3,0x1
    80001514:	19fd                	addi	s3,s3,-1
    80001516:	95ce                	add	a1,a1,s3
    80001518:	79fd                	lui	s3,0xfffff
    8000151a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151e:	08c9f063          	bgeu	s3,a2,8000159e <uvmalloc+0xa6>
    80001522:	894e                	mv	s2,s3
    mem = kalloc();
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	5fc080e7          	jalr	1532(ra) # 80000b20 <kalloc>
    8000152c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000152e:	c51d                	beqz	a0,8000155c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001530:	6605                	lui	a2,0x1
    80001532:	4581                	li	a1,0
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	7d8080e7          	jalr	2008(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000153c:	4779                	li	a4,30
    8000153e:	86a6                	mv	a3,s1
    80001540:	6605                	lui	a2,0x1
    80001542:	85ca                	mv	a1,s2
    80001544:	8556                	mv	a0,s5
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	bb6080e7          	jalr	-1098(ra) # 800010fc <mappages>
    8000154e:	e905                	bnez	a0,8000157e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001550:	6785                	lui	a5,0x1
    80001552:	993e                	add	s2,s2,a5
    80001554:	fd4968e3          	bltu	s2,s4,80001524 <uvmalloc+0x2c>
  return newsz;
    80001558:	8552                	mv	a0,s4
    8000155a:	a809                	j	8000156c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f4e080e7          	jalr	-178(ra) # 800014b0 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
}
    8000156c:	70e2                	ld	ra,56(sp)
    8000156e:	7442                	ld	s0,48(sp)
    80001570:	74a2                	ld	s1,40(sp)
    80001572:	7902                	ld	s2,32(sp)
    80001574:	69e2                	ld	s3,24(sp)
    80001576:	6a42                	ld	s4,16(sp)
    80001578:	6aa2                	ld	s5,8(sp)
    8000157a:	6121                	addi	sp,sp,64
    8000157c:	8082                	ret
      kfree(mem);
    8000157e:	8526                	mv	a0,s1
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	4a4080e7          	jalr	1188(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001588:	864e                	mv	a2,s3
    8000158a:	85ca                	mv	a1,s2
    8000158c:	8556                	mv	a0,s5
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	f22080e7          	jalr	-222(ra) # 800014b0 <uvmdealloc>
      return 0;
    80001596:	4501                	li	a0,0
    80001598:	bfd1                	j	8000156c <uvmalloc+0x74>
    return oldsz;
    8000159a:	852e                	mv	a0,a1
}
    8000159c:	8082                	ret
  return newsz;
    8000159e:	8532                	mv	a0,a2
    800015a0:	b7f1                	j	8000156c <uvmalloc+0x74>

00000000800015a2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015a2:	7179                	addi	sp,sp,-48
    800015a4:	f406                	sd	ra,40(sp)
    800015a6:	f022                	sd	s0,32(sp)
    800015a8:	ec26                	sd	s1,24(sp)
    800015aa:	e84a                	sd	s2,16(sp)
    800015ac:	e44e                	sd	s3,8(sp)
    800015ae:	e052                	sd	s4,0(sp)
    800015b0:	1800                	addi	s0,sp,48
    800015b2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015b4:	84aa                	mv	s1,a0
    800015b6:	6905                	lui	s2,0x1
    800015b8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ba:	4985                	li	s3,1
    800015bc:	a821                	j	800015d4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015be:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015c0:	0532                	slli	a0,a0,0xc
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	fe0080e7          	jalr	-32(ra) # 800015a2 <freewalk>
      pagetable[i] = 0;
    800015ca:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015ce:	04a1                	addi	s1,s1,8
    800015d0:	03248163          	beq	s1,s2,800015f2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015d4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015d6:	00f57793          	andi	a5,a0,15
    800015da:	ff3782e3          	beq	a5,s3,800015be <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015de:	8905                	andi	a0,a0,1
    800015e0:	d57d                	beqz	a0,800015ce <freewalk+0x2c>
      panic("freewalk: leaf");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	b5e50513          	addi	a0,a0,-1186 # 80008140 <digits+0x100>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f5e080e7          	jalr	-162(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015f2:	8552                	mv	a0,s4
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	430080e7          	jalr	1072(ra) # 80000a24 <kfree>
}
    800015fc:	70a2                	ld	ra,40(sp)
    800015fe:	7402                	ld	s0,32(sp)
    80001600:	64e2                	ld	s1,24(sp)
    80001602:	6942                	ld	s2,16(sp)
    80001604:	69a2                	ld	s3,8(sp)
    80001606:	6a02                	ld	s4,0(sp)
    80001608:	6145                	addi	sp,sp,48
    8000160a:	8082                	ret

000000008000160c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000160c:	1101                	addi	sp,sp,-32
    8000160e:	ec06                	sd	ra,24(sp)
    80001610:	e822                	sd	s0,16(sp)
    80001612:	e426                	sd	s1,8(sp)
    80001614:	1000                	addi	s0,sp,32
    80001616:	84aa                	mv	s1,a0
  if(sz > 0)
    80001618:	e999                	bnez	a1,8000162e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000161a:	8526                	mv	a0,s1
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	f86080e7          	jalr	-122(ra) # 800015a2 <freewalk>
}
    80001624:	60e2                	ld	ra,24(sp)
    80001626:	6442                	ld	s0,16(sp)
    80001628:	64a2                	ld	s1,8(sp)
    8000162a:	6105                	addi	sp,sp,32
    8000162c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000162e:	6605                	lui	a2,0x1
    80001630:	167d                	addi	a2,a2,-1
    80001632:	962e                	add	a2,a2,a1
    80001634:	4685                	li	a3,1
    80001636:	8231                	srli	a2,a2,0xc
    80001638:	4581                	li	a1,0
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	d2a080e7          	jalr	-726(ra) # 80001364 <uvmunmap>
    80001642:	bfe1                	j	8000161a <uvmfree+0xe>

0000000080001644 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001644:	ca4d                	beqz	a2,800016f6 <uvmcopy+0xb2>
{
    80001646:	715d                	addi	sp,sp,-80
    80001648:	e486                	sd	ra,72(sp)
    8000164a:	e0a2                	sd	s0,64(sp)
    8000164c:	fc26                	sd	s1,56(sp)
    8000164e:	f84a                	sd	s2,48(sp)
    80001650:	f44e                	sd	s3,40(sp)
    80001652:	f052                	sd	s4,32(sp)
    80001654:	ec56                	sd	s5,24(sp)
    80001656:	e85a                	sd	s6,16(sp)
    80001658:	e45e                	sd	s7,8(sp)
    8000165a:	0880                	addi	s0,sp,80
    8000165c:	8aaa                	mv	s5,a0
    8000165e:	8b2e                	mv	s6,a1
    80001660:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001662:	4481                	li	s1,0
    80001664:	a029                	j	8000166e <uvmcopy+0x2a>
    80001666:	6785                	lui	a5,0x1
    80001668:	94be                	add	s1,s1,a5
    8000166a:	0744fa63          	bgeu	s1,s4,800016de <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    8000166e:	4601                	li	a2,0
    80001670:	85a6                	mv	a1,s1
    80001672:	8556                	mv	a0,s5
    80001674:	00000097          	auipc	ra,0x0
    80001678:	984080e7          	jalr	-1660(ra) # 80000ff8 <walk>
    8000167c:	d56d                	beqz	a0,80001666 <uvmcopy+0x22>
      continue;
      // panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000167e:	6118                	ld	a4,0(a0)
    80001680:	00177793          	andi	a5,a4,1
    80001684:	d3ed                	beqz	a5,80001666 <uvmcopy+0x22>
      continue;
      // panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001686:	00a75593          	srli	a1,a4,0xa
    8000168a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000168e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	48e080e7          	jalr	1166(ra) # 80000b20 <kalloc>
    8000169a:	89aa                	mv	s3,a0
    8000169c:	c515                	beqz	a0,800016c8 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000169e:	6605                	lui	a2,0x1
    800016a0:	85de                	mv	a1,s7
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	6ca080e7          	jalr	1738(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016aa:	874a                	mv	a4,s2
    800016ac:	86ce                	mv	a3,s3
    800016ae:	6605                	lui	a2,0x1
    800016b0:	85a6                	mv	a1,s1
    800016b2:	855a                	mv	a0,s6
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	a48080e7          	jalr	-1464(ra) # 800010fc <mappages>
    800016bc:	d54d                	beqz	a0,80001666 <uvmcopy+0x22>
      kfree(mem);
    800016be:	854e                	mv	a0,s3
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	364080e7          	jalr	868(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c8:	4685                	li	a3,1
    800016ca:	00c4d613          	srli	a2,s1,0xc
    800016ce:	4581                	li	a1,0
    800016d0:	855a                	mv	a0,s6
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	c92080e7          	jalr	-878(ra) # 80001364 <uvmunmap>
  return -1;
    800016da:	557d                	li	a0,-1
    800016dc:	a011                	j	800016e0 <uvmcopy+0x9c>
  return 0;
    800016de:	4501                	li	a0,0
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6161                	addi	sp,sp,80
    800016f4:	8082                	ret
  return 0;
    800016f6:	4501                	li	a0,0
}
    800016f8:	8082                	ret

00000000800016fa <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016fa:	1141                	addi	sp,sp,-16
    800016fc:	e406                	sd	ra,8(sp)
    800016fe:	e022                	sd	s0,0(sp)
    80001700:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001702:	4601                	li	a2,0
    80001704:	00000097          	auipc	ra,0x0
    80001708:	8f4080e7          	jalr	-1804(ra) # 80000ff8 <walk>
  if(pte == 0)
    8000170c:	c901                	beqz	a0,8000171c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000170e:	611c                	ld	a5,0(a0)
    80001710:	9bbd                	andi	a5,a5,-17
    80001712:	e11c                	sd	a5,0(a0)
}
    80001714:	60a2                	ld	ra,8(sp)
    80001716:	6402                	ld	s0,0(sp)
    80001718:	0141                	addi	sp,sp,16
    8000171a:	8082                	ret
    panic("uvmclear");
    8000171c:	00007517          	auipc	a0,0x7
    80001720:	a3450513          	addi	a0,a0,-1484 # 80008150 <digits+0x110>
    80001724:	fffff097          	auipc	ra,0xfffff
    80001728:	e24080e7          	jalr	-476(ra) # 80000548 <panic>

000000008000172c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172c:	c6bd                	beqz	a3,8000179a <copyout+0x6e>
{
    8000172e:	715d                	addi	sp,sp,-80
    80001730:	e486                	sd	ra,72(sp)
    80001732:	e0a2                	sd	s0,64(sp)
    80001734:	fc26                	sd	s1,56(sp)
    80001736:	f84a                	sd	s2,48(sp)
    80001738:	f44e                	sd	s3,40(sp)
    8000173a:	f052                	sd	s4,32(sp)
    8000173c:	ec56                	sd	s5,24(sp)
    8000173e:	e85a                	sd	s6,16(sp)
    80001740:	e45e                	sd	s7,8(sp)
    80001742:	e062                	sd	s8,0(sp)
    80001744:	0880                	addi	s0,sp,80
    80001746:	8b2a                	mv	s6,a0
    80001748:	8c2e                	mv	s8,a1
    8000174a:	8a32                	mv	s4,a2
    8000174c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000174e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001750:	6a85                	lui	s5,0x1
    80001752:	a015                	j	80001776 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001754:	9562                	add	a0,a0,s8
    80001756:	0004861b          	sext.w	a2,s1
    8000175a:	85d2                	mv	a1,s4
    8000175c:	41250533          	sub	a0,a0,s2
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	60c080e7          	jalr	1548(ra) # 80000d6c <memmove>

    len -= n;
    80001768:	409989b3          	sub	s3,s3,s1
    src += n;
    8000176c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000176e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001772:	02098263          	beqz	s3,80001796 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001776:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177a:	85ca                	mv	a1,s2
    8000177c:	855a                	mv	a0,s6
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	a0c080e7          	jalr	-1524(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    80001786:	cd01                	beqz	a0,8000179e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001788:	418904b3          	sub	s1,s2,s8
    8000178c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000178e:	fc99f3e3          	bgeu	s3,s1,80001754 <copyout+0x28>
    80001792:	84ce                	mv	s1,s3
    80001794:	b7c1                	j	80001754 <copyout+0x28>
  }
  return 0;
    80001796:	4501                	li	a0,0
    80001798:	a021                	j	800017a0 <copyout+0x74>
    8000179a:	4501                	li	a0,0
}
    8000179c:	8082                	ret
      return -1;
    8000179e:	557d                	li	a0,-1
}
    800017a0:	60a6                	ld	ra,72(sp)
    800017a2:	6406                	ld	s0,64(sp)
    800017a4:	74e2                	ld	s1,56(sp)
    800017a6:	7942                	ld	s2,48(sp)
    800017a8:	79a2                	ld	s3,40(sp)
    800017aa:	7a02                	ld	s4,32(sp)
    800017ac:	6ae2                	ld	s5,24(sp)
    800017ae:	6b42                	ld	s6,16(sp)
    800017b0:	6ba2                	ld	s7,8(sp)
    800017b2:	6c02                	ld	s8,0(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret

00000000800017b8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017b8:	c6bd                	beqz	a3,80001826 <copyin+0x6e>
{
    800017ba:	715d                	addi	sp,sp,-80
    800017bc:	e486                	sd	ra,72(sp)
    800017be:	e0a2                	sd	s0,64(sp)
    800017c0:	fc26                	sd	s1,56(sp)
    800017c2:	f84a                	sd	s2,48(sp)
    800017c4:	f44e                	sd	s3,40(sp)
    800017c6:	f052                	sd	s4,32(sp)
    800017c8:	ec56                	sd	s5,24(sp)
    800017ca:	e85a                	sd	s6,16(sp)
    800017cc:	e45e                	sd	s7,8(sp)
    800017ce:	e062                	sd	s8,0(sp)
    800017d0:	0880                	addi	s0,sp,80
    800017d2:	8b2a                	mv	s6,a0
    800017d4:	8a2e                	mv	s4,a1
    800017d6:	8c32                	mv	s8,a2
    800017d8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017da:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017dc:	6a85                	lui	s5,0x1
    800017de:	a015                	j	80001802 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e0:	9562                	add	a0,a0,s8
    800017e2:	0004861b          	sext.w	a2,s1
    800017e6:	412505b3          	sub	a1,a0,s2
    800017ea:	8552                	mv	a0,s4
    800017ec:	fffff097          	auipc	ra,0xfffff
    800017f0:	580080e7          	jalr	1408(ra) # 80000d6c <memmove>

    len -= n;
    800017f4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017f8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017fa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017fe:	02098263          	beqz	s3,80001822 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001802:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001806:	85ca                	mv	a1,s2
    80001808:	855a                	mv	a0,s6
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	980080e7          	jalr	-1664(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    80001812:	cd01                	beqz	a0,8000182a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001814:	418904b3          	sub	s1,s2,s8
    80001818:	94d6                	add	s1,s1,s5
    if(n > len)
    8000181a:	fc99f3e3          	bgeu	s3,s1,800017e0 <copyin+0x28>
    8000181e:	84ce                	mv	s1,s3
    80001820:	b7c1                	j	800017e0 <copyin+0x28>
  }
  return 0;
    80001822:	4501                	li	a0,0
    80001824:	a021                	j	8000182c <copyin+0x74>
    80001826:	4501                	li	a0,0
}
    80001828:	8082                	ret
      return -1;
    8000182a:	557d                	li	a0,-1
}
    8000182c:	60a6                	ld	ra,72(sp)
    8000182e:	6406                	ld	s0,64(sp)
    80001830:	74e2                	ld	s1,56(sp)
    80001832:	7942                	ld	s2,48(sp)
    80001834:	79a2                	ld	s3,40(sp)
    80001836:	7a02                	ld	s4,32(sp)
    80001838:	6ae2                	ld	s5,24(sp)
    8000183a:	6b42                	ld	s6,16(sp)
    8000183c:	6ba2                	ld	s7,8(sp)
    8000183e:	6c02                	ld	s8,0(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret

0000000080001844 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001844:	c6c5                	beqz	a3,800018ec <copyinstr+0xa8>
{
    80001846:	715d                	addi	sp,sp,-80
    80001848:	e486                	sd	ra,72(sp)
    8000184a:	e0a2                	sd	s0,64(sp)
    8000184c:	fc26                	sd	s1,56(sp)
    8000184e:	f84a                	sd	s2,48(sp)
    80001850:	f44e                	sd	s3,40(sp)
    80001852:	f052                	sd	s4,32(sp)
    80001854:	ec56                	sd	s5,24(sp)
    80001856:	e85a                	sd	s6,16(sp)
    80001858:	e45e                	sd	s7,8(sp)
    8000185a:	0880                	addi	s0,sp,80
    8000185c:	8a2a                	mv	s4,a0
    8000185e:	8b2e                	mv	s6,a1
    80001860:	8bb2                	mv	s7,a2
    80001862:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001864:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001866:	6985                	lui	s3,0x1
    80001868:	a035                	j	80001894 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000186a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000186e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001870:	0017b793          	seqz	a5,a5
    80001874:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001878:	60a6                	ld	ra,72(sp)
    8000187a:	6406                	ld	s0,64(sp)
    8000187c:	74e2                	ld	s1,56(sp)
    8000187e:	7942                	ld	s2,48(sp)
    80001880:	79a2                	ld	s3,40(sp)
    80001882:	7a02                	ld	s4,32(sp)
    80001884:	6ae2                	ld	s5,24(sp)
    80001886:	6b42                	ld	s6,16(sp)
    80001888:	6ba2                	ld	s7,8(sp)
    8000188a:	6161                	addi	sp,sp,80
    8000188c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000188e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001892:	c8a9                	beqz	s1,800018e4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001894:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001898:	85ca                	mv	a1,s2
    8000189a:	8552                	mv	a0,s4
    8000189c:	00000097          	auipc	ra,0x0
    800018a0:	8ee080e7          	jalr	-1810(ra) # 8000118a <walkaddr>
    if(pa0 == 0)
    800018a4:	c131                	beqz	a0,800018e8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018a6:	41790833          	sub	a6,s2,s7
    800018aa:	984e                	add	a6,a6,s3
    if(n > max)
    800018ac:	0104f363          	bgeu	s1,a6,800018b2 <copyinstr+0x6e>
    800018b0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b2:	955e                	add	a0,a0,s7
    800018b4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018b8:	fc080be3          	beqz	a6,8000188e <copyinstr+0x4a>
    800018bc:	985a                	add	a6,a6,s6
    800018be:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c0:	41650633          	sub	a2,a0,s6
    800018c4:	14fd                	addi	s1,s1,-1
    800018c6:	9b26                	add	s6,s6,s1
    800018c8:	00f60733          	add	a4,a2,a5
    800018cc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018d0:	df49                	beqz	a4,8000186a <copyinstr+0x26>
        *dst = *p;
    800018d2:	00e78023          	sb	a4,0(a5)
      --max;
    800018d6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018da:	0785                	addi	a5,a5,1
    while(n > 0){
    800018dc:	ff0796e3          	bne	a5,a6,800018c8 <copyinstr+0x84>
      dst++;
    800018e0:	8b42                	mv	s6,a6
    800018e2:	b775                	j	8000188e <copyinstr+0x4a>
    800018e4:	4781                	li	a5,0
    800018e6:	b769                	j	80001870 <copyinstr+0x2c>
      return -1;
    800018e8:	557d                	li	a0,-1
    800018ea:	b779                	j	80001878 <copyinstr+0x34>
  int got_null = 0;
    800018ec:	4781                	li	a5,0
  if(got_null){
    800018ee:	0017b793          	seqz	a5,a5
    800018f2:	40f00533          	neg	a0,a5
}
    800018f6:	8082                	ret

00000000800018f8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018f8:	1101                	addi	sp,sp,-32
    800018fa:	ec06                	sd	ra,24(sp)
    800018fc:	e822                	sd	s0,16(sp)
    800018fe:	e426                	sd	s1,8(sp)
    80001900:	1000                	addi	s0,sp,32
    80001902:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	292080e7          	jalr	658(ra) # 80000b96 <holding>
    8000190c:	c909                	beqz	a0,8000191e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000190e:	749c                	ld	a5,40(s1)
    80001910:	00978f63          	beq	a5,s1,8000192e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001914:	60e2                	ld	ra,24(sp)
    80001916:	6442                	ld	s0,16(sp)
    80001918:	64a2                	ld	s1,8(sp)
    8000191a:	6105                	addi	sp,sp,32
    8000191c:	8082                	ret
    panic("wakeup1");
    8000191e:	00007517          	auipc	a0,0x7
    80001922:	84250513          	addi	a0,a0,-1982 # 80008160 <digits+0x120>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	c22080e7          	jalr	-990(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000192e:	4c98                	lw	a4,24(s1)
    80001930:	4785                	li	a5,1
    80001932:	fef711e3          	bne	a4,a5,80001914 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001936:	4789                	li	a5,2
    80001938:	cc9c                	sw	a5,24(s1)
}
    8000193a:	bfe9                	j	80001914 <wakeup1+0x1c>

000000008000193c <procinit>:
{
    8000193c:	715d                	addi	sp,sp,-80
    8000193e:	e486                	sd	ra,72(sp)
    80001940:	e0a2                	sd	s0,64(sp)
    80001942:	fc26                	sd	s1,56(sp)
    80001944:	f84a                	sd	s2,48(sp)
    80001946:	f44e                	sd	s3,40(sp)
    80001948:	f052                	sd	s4,32(sp)
    8000194a:	ec56                	sd	s5,24(sp)
    8000194c:	e85a                	sd	s6,16(sp)
    8000194e:	e45e                	sd	s7,8(sp)
    80001950:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001952:	00007597          	auipc	a1,0x7
    80001956:	81658593          	addi	a1,a1,-2026 # 80008168 <digits+0x128>
    8000195a:	00010517          	auipc	a0,0x10
    8000195e:	ff650513          	addi	a0,a0,-10 # 80011950 <pid_lock>
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	21e080e7          	jalr	542(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	00010917          	auipc	s2,0x10
    8000196e:	3fe90913          	addi	s2,s2,1022 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001972:	00006b97          	auipc	s7,0x6
    80001976:	7feb8b93          	addi	s7,s7,2046 # 80008170 <digits+0x130>
      uint64 va = KSTACK((int) (p - proc));
    8000197a:	8b4a                	mv	s6,s2
    8000197c:	00006a97          	auipc	s5,0x6
    80001980:	684a8a93          	addi	s5,s5,1668 # 80008000 <etext>
    80001984:	040009b7          	lui	s3,0x4000
    80001988:	19fd                	addi	s3,s3,-1
    8000198a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	00016a17          	auipc	s4,0x16
    80001990:	ddca0a13          	addi	s4,s4,-548 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001994:	85de                	mv	a1,s7
    80001996:	854a                	mv	a0,s2
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	1e8080e7          	jalr	488(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	180080e7          	jalr	384(ra) # 80000b20 <kalloc>
    800019a8:	85aa                	mv	a1,a0
      if(pa == 0)
    800019aa:	c929                	beqz	a0,800019fc <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019ac:	416904b3          	sub	s1,s2,s6
    800019b0:	848d                	srai	s1,s1,0x3
    800019b2:	000ab783          	ld	a5,0(s5)
    800019b6:	02f484b3          	mul	s1,s1,a5
    800019ba:	2485                	addiw	s1,s1,1
    800019bc:	00d4949b          	slliw	s1,s1,0xd
    800019c0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019c4:	4699                	li	a3,6
    800019c6:	6605                	lui	a2,0x1
    800019c8:	8526                	mv	a0,s1
    800019ca:	00000097          	auipc	ra,0x0
    800019ce:	890080e7          	jalr	-1904(ra) # 8000125a <kvmmap>
      p->kstack = va;
    800019d2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d6:	16890913          	addi	s2,s2,360
    800019da:	fb491de3          	bne	s2,s4,80001994 <procinit+0x58>
  kvminithart();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	5f6080e7          	jalr	1526(ra) # 80000fd4 <kvminithart>
}
    800019e6:	60a6                	ld	ra,72(sp)
    800019e8:	6406                	ld	s0,64(sp)
    800019ea:	74e2                	ld	s1,56(sp)
    800019ec:	7942                	ld	s2,48(sp)
    800019ee:	79a2                	ld	s3,40(sp)
    800019f0:	7a02                	ld	s4,32(sp)
    800019f2:	6ae2                	ld	s5,24(sp)
    800019f4:	6b42                	ld	s6,16(sp)
    800019f6:	6ba2                	ld	s7,8(sp)
    800019f8:	6161                	addi	sp,sp,80
    800019fa:	8082                	ret
        panic("kalloc");
    800019fc:	00006517          	auipc	a0,0x6
    80001a00:	77c50513          	addi	a0,a0,1916 # 80008178 <digits+0x138>
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	b44080e7          	jalr	-1212(ra) # 80000548 <panic>

0000000080001a0c <cpuid>:
{
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a12:	8512                	mv	a0,tp
}
    80001a14:	2501                	sext.w	a0,a0
    80001a16:	6422                	ld	s0,8(sp)
    80001a18:	0141                	addi	sp,sp,16
    80001a1a:	8082                	ret

0000000080001a1c <mycpu>:
mycpu(void) {
    80001a1c:	1141                	addi	sp,sp,-16
    80001a1e:	e422                	sd	s0,8(sp)
    80001a20:	0800                	addi	s0,sp,16
    80001a22:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a24:	2781                	sext.w	a5,a5
    80001a26:	079e                	slli	a5,a5,0x7
}
    80001a28:	00010517          	auipc	a0,0x10
    80001a2c:	f4050513          	addi	a0,a0,-192 # 80011968 <cpus>
    80001a30:	953e                	add	a0,a0,a5
    80001a32:	6422                	ld	s0,8(sp)
    80001a34:	0141                	addi	sp,sp,16
    80001a36:	8082                	ret

0000000080001a38 <myproc>:
myproc(void) {
    80001a38:	1101                	addi	sp,sp,-32
    80001a3a:	ec06                	sd	ra,24(sp)
    80001a3c:	e822                	sd	s0,16(sp)
    80001a3e:	e426                	sd	s1,8(sp)
    80001a40:	1000                	addi	s0,sp,32
  push_off();
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	182080e7          	jalr	386(ra) # 80000bc4 <push_off>
    80001a4a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a4c:	2781                	sext.w	a5,a5
    80001a4e:	079e                	slli	a5,a5,0x7
    80001a50:	00010717          	auipc	a4,0x10
    80001a54:	f0070713          	addi	a4,a4,-256 # 80011950 <pid_lock>
    80001a58:	97ba                	add	a5,a5,a4
    80001a5a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	208080e7          	jalr	520(ra) # 80000c64 <pop_off>
}
    80001a64:	8526                	mv	a0,s1
    80001a66:	60e2                	ld	ra,24(sp)
    80001a68:	6442                	ld	s0,16(sp)
    80001a6a:	64a2                	ld	s1,8(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <forkret>:
{
    80001a70:	1141                	addi	sp,sp,-16
    80001a72:	e406                	sd	ra,8(sp)
    80001a74:	e022                	sd	s0,0(sp)
    80001a76:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	fc0080e7          	jalr	-64(ra) # 80001a38 <myproc>
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	244080e7          	jalr	580(ra) # 80000cc4 <release>
  if (first) {
    80001a88:	00007797          	auipc	a5,0x7
    80001a8c:	d287a783          	lw	a5,-728(a5) # 800087b0 <first.1662>
    80001a90:	eb89                	bnez	a5,80001aa2 <forkret+0x32>
  usertrapret();
    80001a92:	00001097          	auipc	ra,0x1
    80001a96:	c1c080e7          	jalr	-996(ra) # 800026ae <usertrapret>
}
    80001a9a:	60a2                	ld	ra,8(sp)
    80001a9c:	6402                	ld	s0,0(sp)
    80001a9e:	0141                	addi	sp,sp,16
    80001aa0:	8082                	ret
    first = 0;
    80001aa2:	00007797          	auipc	a5,0x7
    80001aa6:	d007a723          	sw	zero,-754(a5) # 800087b0 <first.1662>
    fsinit(ROOTDEV);
    80001aaa:	4505                	li	a0,1
    80001aac:	00002097          	auipc	ra,0x2
    80001ab0:	9ca080e7          	jalr	-1590(ra) # 80003476 <fsinit>
    80001ab4:	bff9                	j	80001a92 <forkret+0x22>

0000000080001ab6 <allocpid>:
allocpid() {
    80001ab6:	1101                	addi	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	e04a                	sd	s2,0(sp)
    80001ac0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac2:	00010917          	auipc	s2,0x10
    80001ac6:	e8e90913          	addi	s2,s2,-370 # 80011950 <pid_lock>
    80001aca:	854a                	mv	a0,s2
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	144080e7          	jalr	324(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001ad4:	00007797          	auipc	a5,0x7
    80001ad8:	ce078793          	addi	a5,a5,-800 # 800087b4 <nextpid>
    80001adc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ade:	0014871b          	addiw	a4,s1,1
    80001ae2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae4:	854a                	mv	a0,s2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	1de080e7          	jalr	478(ra) # 80000cc4 <release>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6902                	ld	s2,0(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <proc_pagetable>:
{
    80001afc:	1101                	addi	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	e04a                	sd	s2,0(sp)
    80001b06:	1000                	addi	s0,sp,32
    80001b08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	906080e7          	jalr	-1786(ra) # 80001410 <uvmcreate>
    80001b12:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b14:	c121                	beqz	a0,80001b54 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b16:	4729                	li	a4,10
    80001b18:	00005697          	auipc	a3,0x5
    80001b1c:	4e868693          	addi	a3,a3,1256 # 80007000 <_trampoline>
    80001b20:	6605                	lui	a2,0x1
    80001b22:	040005b7          	lui	a1,0x4000
    80001b26:	15fd                	addi	a1,a1,-1
    80001b28:	05b2                	slli	a1,a1,0xc
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	5d2080e7          	jalr	1490(ra) # 800010fc <mappages>
    80001b32:	02054863          	bltz	a0,80001b62 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b36:	4719                	li	a4,6
    80001b38:	05893683          	ld	a3,88(s2)
    80001b3c:	6605                	lui	a2,0x1
    80001b3e:	020005b7          	lui	a1,0x2000
    80001b42:	15fd                	addi	a1,a1,-1
    80001b44:	05b6                	slli	a1,a1,0xd
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	5b4080e7          	jalr	1460(ra) # 800010fc <mappages>
    80001b50:	02054163          	bltz	a0,80001b72 <proc_pagetable+0x76>
}
    80001b54:	8526                	mv	a0,s1
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret
    uvmfree(pagetable, 0);
    80001b62:	4581                	li	a1,0
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	aa6080e7          	jalr	-1370(ra) # 8000160c <uvmfree>
    return 0;
    80001b6e:	4481                	li	s1,0
    80001b70:	b7d5                	j	80001b54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	8526                	mv	a0,s1
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	7e4080e7          	jalr	2020(ra) # 80001364 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b88:	4581                	li	a1,0
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	a80080e7          	jalr	-1408(ra) # 8000160c <uvmfree>
    return 0;
    80001b94:	4481                	li	s1,0
    80001b96:	bf7d                	j	80001b54 <proc_pagetable+0x58>

0000000080001b98 <proc_freepagetable>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	84aa                	mv	s1,a0
    80001ba6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	040005b7          	lui	a1,0x4000
    80001bb0:	15fd                	addi	a1,a1,-1
    80001bb2:	05b2                	slli	a1,a1,0xc
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	7b0080e7          	jalr	1968(ra) # 80001364 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bbc:	4681                	li	a3,0
    80001bbe:	4605                	li	a2,1
    80001bc0:	020005b7          	lui	a1,0x2000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b6                	slli	a1,a1,0xd
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	79a080e7          	jalr	1946(ra) # 80001364 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd2:	85ca                	mv	a1,s2
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	a36080e7          	jalr	-1482(ra) # 8000160c <uvmfree>
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6902                	ld	s2,0(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <freeproc>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	1000                	addi	s0,sp,32
    80001bf4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bf6:	6d28                	ld	a0,88(a0)
    80001bf8:	c509                	beqz	a0,80001c02 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	e2a080e7          	jalr	-470(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001c02:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c06:	68a8                	ld	a0,80(s1)
    80001c08:	c511                	beqz	a0,80001c14 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0a:	64ac                	ld	a1,72(s1)
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	f8c080e7          	jalr	-116(ra) # 80001b98 <proc_freepagetable>
  p->pagetable = 0;
    80001c14:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c18:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c1c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c20:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c24:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c28:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c2c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c30:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c34:	0004ac23          	sw	zero,24(s1)
}
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6105                	addi	sp,sp,32
    80001c40:	8082                	ret

0000000080001c42 <allocproc>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	e04a                	sd	s2,0(sp)
    80001c4c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4e:	00010497          	auipc	s1,0x10
    80001c52:	11a48493          	addi	s1,s1,282 # 80011d68 <proc>
    80001c56:	00016917          	auipc	s2,0x16
    80001c5a:	b1290913          	addi	s2,s2,-1262 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	fb0080e7          	jalr	-80(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001c68:	4c9c                	lw	a5,24(s1)
    80001c6a:	cf81                	beqz	a5,80001c82 <allocproc+0x40>
      release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	056080e7          	jalr	86(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c76:	16848493          	addi	s1,s1,360
    80001c7a:	ff2492e3          	bne	s1,s2,80001c5e <allocproc+0x1c>
  return 0;
    80001c7e:	4481                	li	s1,0
    80001c80:	a0b9                	j	80001cce <allocproc+0x8c>
  p->pid = allocpid();
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	e34080e7          	jalr	-460(ra) # 80001ab6 <allocpid>
    80001c8a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	e94080e7          	jalr	-364(ra) # 80000b20 <kalloc>
    80001c94:	892a                	mv	s2,a0
    80001c96:	eca8                	sd	a0,88(s1)
    80001c98:	c131                	beqz	a0,80001cdc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e60080e7          	jalr	-416(ra) # 80001afc <proc_pagetable>
    80001ca4:	892a                	mv	s2,a0
    80001ca6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ca8:	c129                	beqz	a0,80001cea <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001caa:	07000613          	li	a2,112
    80001cae:	4581                	li	a1,0
    80001cb0:	06048513          	addi	a0,s1,96
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	058080e7          	jalr	88(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001cbc:	00000797          	auipc	a5,0x0
    80001cc0:	db478793          	addi	a5,a5,-588 # 80001a70 <forkret>
    80001cc4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cc6:	60bc                	ld	a5,64(s1)
    80001cc8:	6705                	lui	a4,0x1
    80001cca:	97ba                	add	a5,a5,a4
    80001ccc:	f4bc                	sd	a5,104(s1)
}
    80001cce:	8526                	mv	a0,s1
    80001cd0:	60e2                	ld	ra,24(sp)
    80001cd2:	6442                	ld	s0,16(sp)
    80001cd4:	64a2                	ld	s1,8(sp)
    80001cd6:	6902                	ld	s2,0(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret
    release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fe6080e7          	jalr	-26(ra) # 80000cc4 <release>
    return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	b7dd                	j	80001cce <allocproc+0x8c>
    freeproc(p);
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	efe080e7          	jalr	-258(ra) # 80001bea <freeproc>
    release(&p->lock);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	fce080e7          	jalr	-50(ra) # 80000cc4 <release>
    return 0;
    80001cfe:	84ca                	mv	s1,s2
    80001d00:	b7f9                	j	80001cce <allocproc+0x8c>

0000000080001d02 <userinit>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	f36080e7          	jalr	-202(ra) # 80001c42 <allocproc>
    80001d14:	84aa                	mv	s1,a0
  initproc = p;
    80001d16:	00007797          	auipc	a5,0x7
    80001d1a:	30a7b123          	sd	a0,770(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d1e:	03400613          	li	a2,52
    80001d22:	00007597          	auipc	a1,0x7
    80001d26:	a9e58593          	addi	a1,a1,-1378 # 800087c0 <initcode>
    80001d2a:	6928                	ld	a0,80(a0)
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	712080e7          	jalr	1810(ra) # 8000143e <uvminit>
  p->sz = PGSIZE;
    80001d34:	6785                	lui	a5,0x1
    80001d36:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d38:	6cb8                	ld	a4,88(s1)
    80001d3a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d3e:	6cb8                	ld	a4,88(s1)
    80001d40:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d42:	4641                	li	a2,16
    80001d44:	00006597          	auipc	a1,0x6
    80001d48:	43c58593          	addi	a1,a1,1084 # 80008180 <digits+0x140>
    80001d4c:	15848513          	addi	a0,s1,344
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	112080e7          	jalr	274(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001d58:	00006517          	auipc	a0,0x6
    80001d5c:	43850513          	addi	a0,a0,1080 # 80008190 <digits+0x150>
    80001d60:	00002097          	auipc	ra,0x2
    80001d64:	142080e7          	jalr	322(ra) # 80003ea2 <namei>
    80001d68:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d6c:	4789                	li	a5,2
    80001d6e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d70:	8526                	mv	a0,s1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f52080e7          	jalr	-174(ra) # 80000cc4 <release>
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret

0000000080001d84 <growproc>:
{
    80001d84:	1101                	addi	sp,sp,-32
    80001d86:	ec06                	sd	ra,24(sp)
    80001d88:	e822                	sd	s0,16(sp)
    80001d8a:	e426                	sd	s1,8(sp)
    80001d8c:	e04a                	sd	s2,0(sp)
    80001d8e:	1000                	addi	s0,sp,32
    80001d90:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	ca6080e7          	jalr	-858(ra) # 80001a38 <myproc>
    80001d9a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d9c:	652c                	ld	a1,72(a0)
    80001d9e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001da2:	00904f63          	bgtz	s1,80001dc0 <growproc+0x3c>
  } else if(n < 0){
    80001da6:	0204cc63          	bltz	s1,80001dde <growproc+0x5a>
  p->sz = sz;
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	04c93423          	sd	a2,72(s2)
  return 0;
    80001db2:	4501                	li	a0,0
}
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6902                	ld	s2,0(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc0:	9e25                	addw	a2,a2,s1
    80001dc2:	1602                	slli	a2,a2,0x20
    80001dc4:	9201                	srli	a2,a2,0x20
    80001dc6:	1582                	slli	a1,a1,0x20
    80001dc8:	9181                	srli	a1,a1,0x20
    80001dca:	6928                	ld	a0,80(a0)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	72c080e7          	jalr	1836(ra) # 800014f8 <uvmalloc>
    80001dd4:	0005061b          	sext.w	a2,a0
    80001dd8:	fa69                	bnez	a2,80001daa <growproc+0x26>
      return -1;
    80001dda:	557d                	li	a0,-1
    80001ddc:	bfe1                	j	80001db4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dde:	9e25                	addw	a2,a2,s1
    80001de0:	1602                	slli	a2,a2,0x20
    80001de2:	9201                	srli	a2,a2,0x20
    80001de4:	1582                	slli	a1,a1,0x20
    80001de6:	9181                	srli	a1,a1,0x20
    80001de8:	6928                	ld	a0,80(a0)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	6c6080e7          	jalr	1734(ra) # 800014b0 <uvmdealloc>
    80001df2:	0005061b          	sext.w	a2,a0
    80001df6:	bf55                	j	80001daa <growproc+0x26>

0000000080001df8 <fork>:
{
    80001df8:	7179                	addi	sp,sp,-48
    80001dfa:	f406                	sd	ra,40(sp)
    80001dfc:	f022                	sd	s0,32(sp)
    80001dfe:	ec26                	sd	s1,24(sp)
    80001e00:	e84a                	sd	s2,16(sp)
    80001e02:	e44e                	sd	s3,8(sp)
    80001e04:	e052                	sd	s4,0(sp)
    80001e06:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	c30080e7          	jalr	-976(ra) # 80001a38 <myproc>
    80001e10:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	e30080e7          	jalr	-464(ra) # 80001c42 <allocproc>
    80001e1a:	c175                	beqz	a0,80001efe <fork+0x106>
    80001e1c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e1e:	04893603          	ld	a2,72(s2)
    80001e22:	692c                	ld	a1,80(a0)
    80001e24:	05093503          	ld	a0,80(s2)
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	81c080e7          	jalr	-2020(ra) # 80001644 <uvmcopy>
    80001e30:	04054863          	bltz	a0,80001e80 <fork+0x88>
  np->sz = p->sz;
    80001e34:	04893783          	ld	a5,72(s2)
    80001e38:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e3c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e40:	05893683          	ld	a3,88(s2)
    80001e44:	87b6                	mv	a5,a3
    80001e46:	0589b703          	ld	a4,88(s3)
    80001e4a:	12068693          	addi	a3,a3,288
    80001e4e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e52:	6788                	ld	a0,8(a5)
    80001e54:	6b8c                	ld	a1,16(a5)
    80001e56:	6f90                	ld	a2,24(a5)
    80001e58:	01073023          	sd	a6,0(a4)
    80001e5c:	e708                	sd	a0,8(a4)
    80001e5e:	eb0c                	sd	a1,16(a4)
    80001e60:	ef10                	sd	a2,24(a4)
    80001e62:	02078793          	addi	a5,a5,32
    80001e66:	02070713          	addi	a4,a4,32
    80001e6a:	fed792e3          	bne	a5,a3,80001e4e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e6e:	0589b783          	ld	a5,88(s3)
    80001e72:	0607b823          	sd	zero,112(a5)
    80001e76:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e7a:	15000a13          	li	s4,336
    80001e7e:	a03d                	j	80001eac <fork+0xb4>
    freeproc(np);
    80001e80:	854e                	mv	a0,s3
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	d68080e7          	jalr	-664(ra) # 80001bea <freeproc>
    release(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e38080e7          	jalr	-456(ra) # 80000cc4 <release>
    return -1;
    80001e94:	54fd                	li	s1,-1
    80001e96:	a899                	j	80001eec <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	696080e7          	jalr	1686(ra) # 8000452e <filedup>
    80001ea0:	009987b3          	add	a5,s3,s1
    80001ea4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea6:	04a1                	addi	s1,s1,8
    80001ea8:	01448763          	beq	s1,s4,80001eb6 <fork+0xbe>
    if(p->ofile[i])
    80001eac:	009907b3          	add	a5,s2,s1
    80001eb0:	6388                	ld	a0,0(a5)
    80001eb2:	f17d                	bnez	a0,80001e98 <fork+0xa0>
    80001eb4:	bfcd                	j	80001ea6 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eb6:	15093503          	ld	a0,336(s2)
    80001eba:	00001097          	auipc	ra,0x1
    80001ebe:	7f6080e7          	jalr	2038(ra) # 800036b0 <idup>
    80001ec2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	15890593          	addi	a1,s2,344
    80001ecc:	15898513          	addi	a0,s3,344
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f92080e7          	jalr	-110(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001ed8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001edc:	4789                	li	a5,2
    80001ede:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	de0080e7          	jalr	-544(ra) # 80000cc4 <release>
}
    80001eec:	8526                	mv	a0,s1
    80001eee:	70a2                	ld	ra,40(sp)
    80001ef0:	7402                	ld	s0,32(sp)
    80001ef2:	64e2                	ld	s1,24(sp)
    80001ef4:	6942                	ld	s2,16(sp)
    80001ef6:	69a2                	ld	s3,8(sp)
    80001ef8:	6a02                	ld	s4,0(sp)
    80001efa:	6145                	addi	sp,sp,48
    80001efc:	8082                	ret
    return -1;
    80001efe:	54fd                	li	s1,-1
    80001f00:	b7f5                	j	80001eec <fork+0xf4>

0000000080001f02 <reparent>:
{
    80001f02:	7179                	addi	sp,sp,-48
    80001f04:	f406                	sd	ra,40(sp)
    80001f06:	f022                	sd	s0,32(sp)
    80001f08:	ec26                	sd	s1,24(sp)
    80001f0a:	e84a                	sd	s2,16(sp)
    80001f0c:	e44e                	sd	s3,8(sp)
    80001f0e:	e052                	sd	s4,0(sp)
    80001f10:	1800                	addi	s0,sp,48
    80001f12:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f14:	00010497          	auipc	s1,0x10
    80001f18:	e5448493          	addi	s1,s1,-428 # 80011d68 <proc>
      pp->parent = initproc;
    80001f1c:	00007a17          	auipc	s4,0x7
    80001f20:	0fca0a13          	addi	s4,s4,252 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f24:	00016997          	auipc	s3,0x16
    80001f28:	84498993          	addi	s3,s3,-1980 # 80017768 <tickslock>
    80001f2c:	a029                	j	80001f36 <reparent+0x34>
    80001f2e:	16848493          	addi	s1,s1,360
    80001f32:	03348363          	beq	s1,s3,80001f58 <reparent+0x56>
    if(pp->parent == p){
    80001f36:	709c                	ld	a5,32(s1)
    80001f38:	ff279be3          	bne	a5,s2,80001f2e <reparent+0x2c>
      acquire(&pp->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	cd2080e7          	jalr	-814(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001f46:	000a3783          	ld	a5,0(s4)
    80001f4a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	d76080e7          	jalr	-650(ra) # 80000cc4 <release>
    80001f56:	bfe1                	j	80001f2e <reparent+0x2c>
}
    80001f58:	70a2                	ld	ra,40(sp)
    80001f5a:	7402                	ld	s0,32(sp)
    80001f5c:	64e2                	ld	s1,24(sp)
    80001f5e:	6942                	ld	s2,16(sp)
    80001f60:	69a2                	ld	s3,8(sp)
    80001f62:	6a02                	ld	s4,0(sp)
    80001f64:	6145                	addi	sp,sp,48
    80001f66:	8082                	ret

0000000080001f68 <scheduler>:
{
    80001f68:	711d                	addi	sp,sp,-96
    80001f6a:	ec86                	sd	ra,88(sp)
    80001f6c:	e8a2                	sd	s0,80(sp)
    80001f6e:	e4a6                	sd	s1,72(sp)
    80001f70:	e0ca                	sd	s2,64(sp)
    80001f72:	fc4e                	sd	s3,56(sp)
    80001f74:	f852                	sd	s4,48(sp)
    80001f76:	f456                	sd	s5,40(sp)
    80001f78:	f05a                	sd	s6,32(sp)
    80001f7a:	ec5e                	sd	s7,24(sp)
    80001f7c:	e862                	sd	s8,16(sp)
    80001f7e:	e466                	sd	s9,8(sp)
    80001f80:	1080                	addi	s0,sp,96
    80001f82:	8792                	mv	a5,tp
  int id = r_tp();
    80001f84:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f86:	00779c13          	slli	s8,a5,0x7
    80001f8a:	00010717          	auipc	a4,0x10
    80001f8e:	9c670713          	addi	a4,a4,-1594 # 80011950 <pid_lock>
    80001f92:	9762                	add	a4,a4,s8
    80001f94:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f98:	00010717          	auipc	a4,0x10
    80001f9c:	9d870713          	addi	a4,a4,-1576 # 80011970 <cpus+0x8>
    80001fa0:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001fa2:	4a89                	li	s5,2
        c->proc = p;
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	00010b17          	auipc	s6,0x10
    80001faa:	9aab0b13          	addi	s6,s6,-1622 # 80011950 <pid_lock>
    80001fae:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb0:	00015a17          	auipc	s4,0x15
    80001fb4:	7b8a0a13          	addi	s4,s4,1976 # 80017768 <tickslock>
    int nproc = 0;
    80001fb8:	4c81                	li	s9,0
    80001fba:	a8a1                	j	80002012 <scheduler+0xaa>
        p->state = RUNNING;
    80001fbc:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fc0:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001fc4:	06048593          	addi	a1,s1,96
    80001fc8:	8562                	mv	a0,s8
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	63a080e7          	jalr	1594(ra) # 80002604 <swtch>
        c->proc = 0;
    80001fd2:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	cec080e7          	jalr	-788(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	16848493          	addi	s1,s1,360
    80001fe4:	01448d63          	beq	s1,s4,80001ffe <scheduler+0x96>
      acquire(&p->lock);
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	c26080e7          	jalr	-986(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    80001ff2:	4c9c                	lw	a5,24(s1)
    80001ff4:	d3ed                	beqz	a5,80001fd6 <scheduler+0x6e>
        nproc++;
    80001ff6:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001ff8:	fd579fe3          	bne	a5,s5,80001fd6 <scheduler+0x6e>
    80001ffc:	b7c1                	j	80001fbc <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001ffe:	013aca63          	blt	s5,s3,80002012 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002002:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002006:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000200e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002012:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002016:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201a:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000201e:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002020:	00010497          	auipc	s1,0x10
    80002024:	d4848493          	addi	s1,s1,-696 # 80011d68 <proc>
        p->state = RUNNING;
    80002028:	4b8d                	li	s7,3
    8000202a:	bf7d                	j	80001fe8 <scheduler+0x80>

000000008000202c <sched>:
{
    8000202c:	7179                	addi	sp,sp,-48
    8000202e:	f406                	sd	ra,40(sp)
    80002030:	f022                	sd	s0,32(sp)
    80002032:	ec26                	sd	s1,24(sp)
    80002034:	e84a                	sd	s2,16(sp)
    80002036:	e44e                	sd	s3,8(sp)
    80002038:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	9fe080e7          	jalr	-1538(ra) # 80001a38 <myproc>
    80002042:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	b52080e7          	jalr	-1198(ra) # 80000b96 <holding>
    8000204c:	c93d                	beqz	a0,800020c2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	00010717          	auipc	a4,0x10
    80002058:	8fc70713          	addi	a4,a4,-1796 # 80011950 <pid_lock>
    8000205c:	97ba                	add	a5,a5,a4
    8000205e:	0907a703          	lw	a4,144(a5)
    80002062:	4785                	li	a5,1
    80002064:	06f71763          	bne	a4,a5,800020d2 <sched+0xa6>
  if(p->state == RUNNING)
    80002068:	4c98                	lw	a4,24(s1)
    8000206a:	478d                	li	a5,3
    8000206c:	06f70b63          	beq	a4,a5,800020e2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002070:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002074:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002076:	efb5                	bnez	a5,800020f2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002078:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000207a:	00010917          	auipc	s2,0x10
    8000207e:	8d690913          	addi	s2,s2,-1834 # 80011950 <pid_lock>
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	97ca                	add	a5,a5,s2
    80002088:	0947a983          	lw	s3,148(a5)
    8000208c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000208e:	2781                	sext.w	a5,a5
    80002090:	079e                	slli	a5,a5,0x7
    80002092:	00010597          	auipc	a1,0x10
    80002096:	8de58593          	addi	a1,a1,-1826 # 80011970 <cpus+0x8>
    8000209a:	95be                	add	a1,a1,a5
    8000209c:	06048513          	addi	a0,s1,96
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	564080e7          	jalr	1380(ra) # 80002604 <swtch>
    800020a8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020aa:	2781                	sext.w	a5,a5
    800020ac:	079e                	slli	a5,a5,0x7
    800020ae:	97ca                	add	a5,a5,s2
    800020b0:	0937aa23          	sw	s3,148(a5)
}
    800020b4:	70a2                	ld	ra,40(sp)
    800020b6:	7402                	ld	s0,32(sp)
    800020b8:	64e2                	ld	s1,24(sp)
    800020ba:	6942                	ld	s2,16(sp)
    800020bc:	69a2                	ld	s3,8(sp)
    800020be:	6145                	addi	sp,sp,48
    800020c0:	8082                	ret
    panic("sched p->lock");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	0d650513          	addi	a0,a0,214 # 80008198 <digits+0x158>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	47e080e7          	jalr	1150(ra) # 80000548 <panic>
    panic("sched locks");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	0d650513          	addi	a0,a0,214 # 800081a8 <digits+0x168>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	46e080e7          	jalr	1134(ra) # 80000548 <panic>
    panic("sched running");
    800020e2:	00006517          	auipc	a0,0x6
    800020e6:	0d650513          	addi	a0,a0,214 # 800081b8 <digits+0x178>
    800020ea:	ffffe097          	auipc	ra,0xffffe
    800020ee:	45e080e7          	jalr	1118(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020f2:	00006517          	auipc	a0,0x6
    800020f6:	0d650513          	addi	a0,a0,214 # 800081c8 <digits+0x188>
    800020fa:	ffffe097          	auipc	ra,0xffffe
    800020fe:	44e080e7          	jalr	1102(ra) # 80000548 <panic>

0000000080002102 <exit>:
{
    80002102:	7179                	addi	sp,sp,-48
    80002104:	f406                	sd	ra,40(sp)
    80002106:	f022                	sd	s0,32(sp)
    80002108:	ec26                	sd	s1,24(sp)
    8000210a:	e84a                	sd	s2,16(sp)
    8000210c:	e44e                	sd	s3,8(sp)
    8000210e:	e052                	sd	s4,0(sp)
    80002110:	1800                	addi	s0,sp,48
    80002112:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002114:	00000097          	auipc	ra,0x0
    80002118:	924080e7          	jalr	-1756(ra) # 80001a38 <myproc>
    8000211c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000211e:	00007797          	auipc	a5,0x7
    80002122:	efa7b783          	ld	a5,-262(a5) # 80009018 <initproc>
    80002126:	0d050493          	addi	s1,a0,208
    8000212a:	15050913          	addi	s2,a0,336
    8000212e:	02a79363          	bne	a5,a0,80002154 <exit+0x52>
    panic("init exiting");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	0ae50513          	addi	a0,a0,174 # 800081e0 <digits+0x1a0>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	40e080e7          	jalr	1038(ra) # 80000548 <panic>
      fileclose(f);
    80002142:	00002097          	auipc	ra,0x2
    80002146:	43e080e7          	jalr	1086(ra) # 80004580 <fileclose>
      p->ofile[fd] = 0;
    8000214a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000214e:	04a1                	addi	s1,s1,8
    80002150:	01248563          	beq	s1,s2,8000215a <exit+0x58>
    if(p->ofile[fd]){
    80002154:	6088                	ld	a0,0(s1)
    80002156:	f575                	bnez	a0,80002142 <exit+0x40>
    80002158:	bfdd                	j	8000214e <exit+0x4c>
  begin_op();
    8000215a:	00002097          	auipc	ra,0x2
    8000215e:	f54080e7          	jalr	-172(ra) # 800040ae <begin_op>
  iput(p->cwd);
    80002162:	1509b503          	ld	a0,336(s3)
    80002166:	00001097          	auipc	ra,0x1
    8000216a:	742080e7          	jalr	1858(ra) # 800038a8 <iput>
  end_op();
    8000216e:	00002097          	auipc	ra,0x2
    80002172:	fc0080e7          	jalr	-64(ra) # 8000412e <end_op>
  p->cwd = 0;
    80002176:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000217a:	00007497          	auipc	s1,0x7
    8000217e:	e9e48493          	addi	s1,s1,-354 # 80009018 <initproc>
    80002182:	6088                	ld	a0,0(s1)
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a8c080e7          	jalr	-1396(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000218c:	6088                	ld	a0,0(s1)
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	76a080e7          	jalr	1898(ra) # 800018f8 <wakeup1>
  release(&initproc->lock);
    80002196:	6088                	ld	a0,0(s1)
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b2c080e7          	jalr	-1236(ra) # 80000cc4 <release>
  acquire(&p->lock);
    800021a0:	854e                	mv	a0,s3
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	a6e080e7          	jalr	-1426(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    800021aa:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021ae:	854e                	mv	a0,s3
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b14080e7          	jalr	-1260(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a56080e7          	jalr	-1450(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800021c2:	854e                	mv	a0,s3
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	a4c080e7          	jalr	-1460(ra) # 80000c10 <acquire>
  reparent(p);
    800021cc:	854e                	mv	a0,s3
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	d34080e7          	jalr	-716(ra) # 80001f02 <reparent>
  wakeup1(original_parent);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	720080e7          	jalr	1824(ra) # 800018f8 <wakeup1>
  p->xstate = status;
    800021e0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021e4:	4791                	li	a5,4
    800021e6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	ad8080e7          	jalr	-1320(ra) # 80000cc4 <release>
  sched();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	e38080e7          	jalr	-456(ra) # 8000202c <sched>
  panic("zombie exit");
    800021fc:	00006517          	auipc	a0,0x6
    80002200:	ff450513          	addi	a0,a0,-12 # 800081f0 <digits+0x1b0>
    80002204:	ffffe097          	auipc	ra,0xffffe
    80002208:	344080e7          	jalr	836(ra) # 80000548 <panic>

000000008000220c <yield>:
{
    8000220c:	1101                	addi	sp,sp,-32
    8000220e:	ec06                	sd	ra,24(sp)
    80002210:	e822                	sd	s0,16(sp)
    80002212:	e426                	sd	s1,8(sp)
    80002214:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	822080e7          	jalr	-2014(ra) # 80001a38 <myproc>
    8000221e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9f0080e7          	jalr	-1552(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    80002228:	4789                	li	a5,2
    8000222a:	cc9c                	sw	a5,24(s1)
  sched();
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	e00080e7          	jalr	-512(ra) # 8000202c <sched>
  release(&p->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>
}
    8000223e:	60e2                	ld	ra,24(sp)
    80002240:	6442                	ld	s0,16(sp)
    80002242:	64a2                	ld	s1,8(sp)
    80002244:	6105                	addi	sp,sp,32
    80002246:	8082                	ret

0000000080002248 <sleep>:
{
    80002248:	7179                	addi	sp,sp,-48
    8000224a:	f406                	sd	ra,40(sp)
    8000224c:	f022                	sd	s0,32(sp)
    8000224e:	ec26                	sd	s1,24(sp)
    80002250:	e84a                	sd	s2,16(sp)
    80002252:	e44e                	sd	s3,8(sp)
    80002254:	1800                	addi	s0,sp,48
    80002256:	89aa                	mv	s3,a0
    80002258:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	7de080e7          	jalr	2014(ra) # 80001a38 <myproc>
    80002262:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002264:	05250663          	beq	a0,s2,800022b0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	9a8080e7          	jalr	-1624(ra) # 80000c10 <acquire>
    release(lk);
    80002270:	854a                	mv	a0,s2
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a52080e7          	jalr	-1454(ra) # 80000cc4 <release>
  p->chan = chan;
    8000227a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000227e:	4785                	li	a5,1
    80002280:	cc9c                	sw	a5,24(s1)
  sched();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	daa080e7          	jalr	-598(ra) # 8000202c <sched>
  p->chan = 0;
    8000228a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a34080e7          	jalr	-1484(ra) # 80000cc4 <release>
    acquire(lk);
    80002298:	854a                	mv	a0,s2
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	976080e7          	jalr	-1674(ra) # 80000c10 <acquire>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6145                	addi	sp,sp,48
    800022ae:	8082                	ret
  p->chan = chan;
    800022b0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022b4:	4785                	li	a5,1
    800022b6:	cd1c                	sw	a5,24(a0)
  sched();
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	d74080e7          	jalr	-652(ra) # 8000202c <sched>
  p->chan = 0;
    800022c0:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022c4:	bff9                	j	800022a2 <sleep+0x5a>

00000000800022c6 <wait>:
{
    800022c6:	715d                	addi	sp,sp,-80
    800022c8:	e486                	sd	ra,72(sp)
    800022ca:	e0a2                	sd	s0,64(sp)
    800022cc:	fc26                	sd	s1,56(sp)
    800022ce:	f84a                	sd	s2,48(sp)
    800022d0:	f44e                	sd	s3,40(sp)
    800022d2:	f052                	sd	s4,32(sp)
    800022d4:	ec56                	sd	s5,24(sp)
    800022d6:	e85a                	sd	s6,16(sp)
    800022d8:	e45e                	sd	s7,8(sp)
    800022da:	e062                	sd	s8,0(sp)
    800022dc:	0880                	addi	s0,sp,80
    800022de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	758080e7          	jalr	1880(ra) # 80001a38 <myproc>
    800022e8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022ea:	8c2a                	mv	s8,a0
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	924080e7          	jalr	-1756(ra) # 80000c10 <acquire>
    havekids = 0;
    800022f4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022f6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f8:	00015997          	auipc	s3,0x15
    800022fc:	47098993          	addi	s3,s3,1136 # 80017768 <tickslock>
        havekids = 1;
    80002300:	4a85                	li	s5,1
    havekids = 0;
    80002302:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002304:	00010497          	auipc	s1,0x10
    80002308:	a6448493          	addi	s1,s1,-1436 # 80011d68 <proc>
    8000230c:	a08d                	j	8000236e <wait+0xa8>
          pid = np->pid;
    8000230e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002312:	000b0e63          	beqz	s6,8000232e <wait+0x68>
    80002316:	4691                	li	a3,4
    80002318:	03448613          	addi	a2,s1,52
    8000231c:	85da                	mv	a1,s6
    8000231e:	05093503          	ld	a0,80(s2)
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	40a080e7          	jalr	1034(ra) # 8000172c <copyout>
    8000232a:	02054263          	bltz	a0,8000234e <wait+0x88>
          freeproc(np);
    8000232e:	8526                	mv	a0,s1
    80002330:	00000097          	auipc	ra,0x0
    80002334:	8ba080e7          	jalr	-1862(ra) # 80001bea <freeproc>
          release(&np->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	98a080e7          	jalr	-1654(ra) # 80000cc4 <release>
          release(&p->lock);
    80002342:	854a                	mv	a0,s2
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	980080e7          	jalr	-1664(ra) # 80000cc4 <release>
          return pid;
    8000234c:	a8a9                	j	800023a6 <wait+0xe0>
            release(&np->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	974080e7          	jalr	-1676(ra) # 80000cc4 <release>
            release(&p->lock);
    80002358:	854a                	mv	a0,s2
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	96a080e7          	jalr	-1686(ra) # 80000cc4 <release>
            return -1;
    80002362:	59fd                	li	s3,-1
    80002364:	a089                	j	800023a6 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002366:	16848493          	addi	s1,s1,360
    8000236a:	03348463          	beq	s1,s3,80002392 <wait+0xcc>
      if(np->parent == p){
    8000236e:	709c                	ld	a5,32(s1)
    80002370:	ff279be3          	bne	a5,s2,80002366 <wait+0xa0>
        acquire(&np->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	89a080e7          	jalr	-1894(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000237e:	4c9c                	lw	a5,24(s1)
    80002380:	f94787e3          	beq	a5,s4,8000230e <wait+0x48>
        release(&np->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	93e080e7          	jalr	-1730(ra) # 80000cc4 <release>
        havekids = 1;
    8000238e:	8756                	mv	a4,s5
    80002390:	bfd9                	j	80002366 <wait+0xa0>
    if(!havekids || p->killed){
    80002392:	c701                	beqz	a4,8000239a <wait+0xd4>
    80002394:	03092783          	lw	a5,48(s2)
    80002398:	c785                	beqz	a5,800023c0 <wait+0xfa>
      release(&p->lock);
    8000239a:	854a                	mv	a0,s2
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	928080e7          	jalr	-1752(ra) # 80000cc4 <release>
      return -1;
    800023a4:	59fd                	li	s3,-1
}
    800023a6:	854e                	mv	a0,s3
    800023a8:	60a6                	ld	ra,72(sp)
    800023aa:	6406                	ld	s0,64(sp)
    800023ac:	74e2                	ld	s1,56(sp)
    800023ae:	7942                	ld	s2,48(sp)
    800023b0:	79a2                	ld	s3,40(sp)
    800023b2:	7a02                	ld	s4,32(sp)
    800023b4:	6ae2                	ld	s5,24(sp)
    800023b6:	6b42                	ld	s6,16(sp)
    800023b8:	6ba2                	ld	s7,8(sp)
    800023ba:	6c02                	ld	s8,0(sp)
    800023bc:	6161                	addi	sp,sp,80
    800023be:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023c0:	85e2                	mv	a1,s8
    800023c2:	854a                	mv	a0,s2
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	e84080e7          	jalr	-380(ra) # 80002248 <sleep>
    havekids = 0;
    800023cc:	bf1d                	j	80002302 <wait+0x3c>

00000000800023ce <wakeup>:
{
    800023ce:	7139                	addi	sp,sp,-64
    800023d0:	fc06                	sd	ra,56(sp)
    800023d2:	f822                	sd	s0,48(sp)
    800023d4:	f426                	sd	s1,40(sp)
    800023d6:	f04a                	sd	s2,32(sp)
    800023d8:	ec4e                	sd	s3,24(sp)
    800023da:	e852                	sd	s4,16(sp)
    800023dc:	e456                	sd	s5,8(sp)
    800023de:	0080                	addi	s0,sp,64
    800023e0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e2:	00010497          	auipc	s1,0x10
    800023e6:	98648493          	addi	s1,s1,-1658 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023ea:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023ec:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ee:	00015917          	auipc	s2,0x15
    800023f2:	37a90913          	addi	s2,s2,890 # 80017768 <tickslock>
    800023f6:	a821                	j	8000240e <wakeup+0x40>
      p->state = RUNNABLE;
    800023f8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	8c6080e7          	jalr	-1850(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002406:	16848493          	addi	s1,s1,360
    8000240a:	01248e63          	beq	s1,s2,80002426 <wakeup+0x58>
    acquire(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	800080e7          	jalr	-2048(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	ff3791e3          	bne	a5,s3,800023fc <wakeup+0x2e>
    8000241e:	749c                	ld	a5,40(s1)
    80002420:	fd479ee3          	bne	a5,s4,800023fc <wakeup+0x2e>
    80002424:	bfd1                	j	800023f8 <wakeup+0x2a>
}
    80002426:	70e2                	ld	ra,56(sp)
    80002428:	7442                	ld	s0,48(sp)
    8000242a:	74a2                	ld	s1,40(sp)
    8000242c:	7902                	ld	s2,32(sp)
    8000242e:	69e2                	ld	s3,24(sp)
    80002430:	6a42                	ld	s4,16(sp)
    80002432:	6aa2                	ld	s5,8(sp)
    80002434:	6121                	addi	sp,sp,64
    80002436:	8082                	ret

0000000080002438 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	1800                	addi	s0,sp,48
    80002446:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002448:	00010497          	auipc	s1,0x10
    8000244c:	92048493          	addi	s1,s1,-1760 # 80011d68 <proc>
    80002450:	00015997          	auipc	s3,0x15
    80002454:	31898993          	addi	s3,s3,792 # 80017768 <tickslock>
    acquire(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	7b6080e7          	jalr	1974(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002462:	5c9c                	lw	a5,56(s1)
    80002464:	01278d63          	beq	a5,s2,8000247e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	85a080e7          	jalr	-1958(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002472:	16848493          	addi	s1,s1,360
    80002476:	ff3491e3          	bne	s1,s3,80002458 <kill+0x20>
  }
  return -1;
    8000247a:	557d                	li	a0,-1
    8000247c:	a829                	j	80002496 <kill+0x5e>
      p->killed = 1;
    8000247e:	4785                	li	a5,1
    80002480:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002482:	4c98                	lw	a4,24(s1)
    80002484:	4785                	li	a5,1
    80002486:	00f70f63          	beq	a4,a5,800024a4 <kill+0x6c>
      release(&p->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	838080e7          	jalr	-1992(ra) # 80000cc4 <release>
      return 0;
    80002494:	4501                	li	a0,0
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6145                	addi	sp,sp,48
    800024a2:	8082                	ret
        p->state = RUNNABLE;
    800024a4:	4789                	li	a5,2
    800024a6:	cc9c                	sw	a5,24(s1)
    800024a8:	b7cd                	j	8000248a <kill+0x52>

00000000800024aa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	84aa                	mv	s1,a0
    800024bc:	892e                	mv	s2,a1
    800024be:	89b2                	mv	s3,a2
    800024c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	576080e7          	jalr	1398(ra) # 80001a38 <myproc>
  if(user_dst){
    800024ca:	c08d                	beqz	s1,800024ec <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	258080e7          	jalr	600(ra) # 8000172c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret
    memmove((char *)dst, src, len);
    800024ec:	000a061b          	sext.w	a2,s4
    800024f0:	85ce                	mv	a1,s3
    800024f2:	854a                	mv	a0,s2
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	878080e7          	jalr	-1928(ra) # 80000d6c <memmove>
    return 0;
    800024fc:	8526                	mv	a0,s1
    800024fe:	bff9                	j	800024dc <either_copyout+0x32>

0000000080002500 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002500:	7179                	addi	sp,sp,-48
    80002502:	f406                	sd	ra,40(sp)
    80002504:	f022                	sd	s0,32(sp)
    80002506:	ec26                	sd	s1,24(sp)
    80002508:	e84a                	sd	s2,16(sp)
    8000250a:	e44e                	sd	s3,8(sp)
    8000250c:	e052                	sd	s4,0(sp)
    8000250e:	1800                	addi	s0,sp,48
    80002510:	892a                	mv	s2,a0
    80002512:	84ae                	mv	s1,a1
    80002514:	89b2                	mv	s3,a2
    80002516:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	520080e7          	jalr	1312(ra) # 80001a38 <myproc>
  if(user_src){
    80002520:	c08d                	beqz	s1,80002542 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002522:	86d2                	mv	a3,s4
    80002524:	864e                	mv	a2,s3
    80002526:	85ca                	mv	a1,s2
    80002528:	6928                	ld	a0,80(a0)
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	28e080e7          	jalr	654(ra) # 800017b8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002532:	70a2                	ld	ra,40(sp)
    80002534:	7402                	ld	s0,32(sp)
    80002536:	64e2                	ld	s1,24(sp)
    80002538:	6942                	ld	s2,16(sp)
    8000253a:	69a2                	ld	s3,8(sp)
    8000253c:	6a02                	ld	s4,0(sp)
    8000253e:	6145                	addi	sp,sp,48
    80002540:	8082                	ret
    memmove(dst, (char*)src, len);
    80002542:	000a061b          	sext.w	a2,s4
    80002546:	85ce                	mv	a1,s3
    80002548:	854a                	mv	a0,s2
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	822080e7          	jalr	-2014(ra) # 80000d6c <memmove>
    return 0;
    80002552:	8526                	mv	a0,s1
    80002554:	bff9                	j	80002532 <either_copyin+0x32>

0000000080002556 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002556:	715d                	addi	sp,sp,-80
    80002558:	e486                	sd	ra,72(sp)
    8000255a:	e0a2                	sd	s0,64(sp)
    8000255c:	fc26                	sd	s1,56(sp)
    8000255e:	f84a                	sd	s2,48(sp)
    80002560:	f44e                	sd	s3,40(sp)
    80002562:	f052                	sd	s4,32(sp)
    80002564:	ec56                	sd	s5,24(sp)
    80002566:	e85a                	sd	s6,16(sp)
    80002568:	e45e                	sd	s7,8(sp)
    8000256a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	01e080e7          	jalr	30(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257c:	00010497          	auipc	s1,0x10
    80002580:	94448493          	addi	s1,s1,-1724 # 80011ec0 <proc+0x158>
    80002584:	00015917          	auipc	s2,0x15
    80002588:	33c90913          	addi	s2,s2,828 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000258e:	00006997          	auipc	s3,0x6
    80002592:	c7298993          	addi	s3,s3,-910 # 80008200 <digits+0x1c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002596:	00006a97          	auipc	s5,0x6
    8000259a:	c72a8a93          	addi	s5,s5,-910 # 80008208 <digits+0x1c8>
    printf("\n");
    8000259e:	00006a17          	auipc	s4,0x6
    800025a2:	b2aa0a13          	addi	s4,s4,-1238 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	00006b97          	auipc	s7,0x6
    800025aa:	c9ab8b93          	addi	s7,s7,-870 # 80008240 <states.1702>
    800025ae:	a00d                	j	800025d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b0:	ee06a583          	lw	a1,-288(a3)
    800025b4:	8556                	mv	a0,s5
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	fdc080e7          	jalr	-36(ra) # 80000592 <printf>
    printf("\n");
    800025be:	8552                	mv	a0,s4
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	fd2080e7          	jalr	-46(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c8:	16848493          	addi	s1,s1,360
    800025cc:	03248163          	beq	s1,s2,800025ee <procdump+0x98>
    if(p->state == UNUSED)
    800025d0:	86a6                	mv	a3,s1
    800025d2:	ec04a783          	lw	a5,-320(s1)
    800025d6:	dbed                	beqz	a5,800025c8 <procdump+0x72>
      state = "???";
    800025d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025da:	fcfb6be3          	bltu	s6,a5,800025b0 <procdump+0x5a>
    800025de:	1782                	slli	a5,a5,0x20
    800025e0:	9381                	srli	a5,a5,0x20
    800025e2:	078e                	slli	a5,a5,0x3
    800025e4:	97de                	add	a5,a5,s7
    800025e6:	6390                	ld	a2,0(a5)
    800025e8:	f661                	bnez	a2,800025b0 <procdump+0x5a>
      state = "???";
    800025ea:	864e                	mv	a2,s3
    800025ec:	b7d1                	j	800025b0 <procdump+0x5a>
  }
}
    800025ee:	60a6                	ld	ra,72(sp)
    800025f0:	6406                	ld	s0,64(sp)
    800025f2:	74e2                	ld	s1,56(sp)
    800025f4:	7942                	ld	s2,48(sp)
    800025f6:	79a2                	ld	s3,40(sp)
    800025f8:	7a02                	ld	s4,32(sp)
    800025fa:	6ae2                	ld	s5,24(sp)
    800025fc:	6b42                	ld	s6,16(sp)
    800025fe:	6ba2                	ld	s7,8(sp)
    80002600:	6161                	addi	sp,sp,80
    80002602:	8082                	ret

0000000080002604 <swtch>:
    80002604:	00153023          	sd	ra,0(a0)
    80002608:	00253423          	sd	sp,8(a0)
    8000260c:	e900                	sd	s0,16(a0)
    8000260e:	ed04                	sd	s1,24(a0)
    80002610:	03253023          	sd	s2,32(a0)
    80002614:	03353423          	sd	s3,40(a0)
    80002618:	03453823          	sd	s4,48(a0)
    8000261c:	03553c23          	sd	s5,56(a0)
    80002620:	05653023          	sd	s6,64(a0)
    80002624:	05753423          	sd	s7,72(a0)
    80002628:	05853823          	sd	s8,80(a0)
    8000262c:	05953c23          	sd	s9,88(a0)
    80002630:	07a53023          	sd	s10,96(a0)
    80002634:	07b53423          	sd	s11,104(a0)
    80002638:	0005b083          	ld	ra,0(a1)
    8000263c:	0085b103          	ld	sp,8(a1)
    80002640:	6980                	ld	s0,16(a1)
    80002642:	6d84                	ld	s1,24(a1)
    80002644:	0205b903          	ld	s2,32(a1)
    80002648:	0285b983          	ld	s3,40(a1)
    8000264c:	0305ba03          	ld	s4,48(a1)
    80002650:	0385ba83          	ld	s5,56(a1)
    80002654:	0405bb03          	ld	s6,64(a1)
    80002658:	0485bb83          	ld	s7,72(a1)
    8000265c:	0505bc03          	ld	s8,80(a1)
    80002660:	0585bc83          	ld	s9,88(a1)
    80002664:	0605bd03          	ld	s10,96(a1)
    80002668:	0685bd83          	ld	s11,104(a1)
    8000266c:	8082                	ret

000000008000266e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000266e:	1141                	addi	sp,sp,-16
    80002670:	e406                	sd	ra,8(sp)
    80002672:	e022                	sd	s0,0(sp)
    80002674:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002676:	00006597          	auipc	a1,0x6
    8000267a:	bf258593          	addi	a1,a1,-1038 # 80008268 <states.1702+0x28>
    8000267e:	00015517          	auipc	a0,0x15
    80002682:	0ea50513          	addi	a0,a0,234 # 80017768 <tickslock>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	4fa080e7          	jalr	1274(ra) # 80000b80 <initlock>
}
    8000268e:	60a2                	ld	ra,8(sp)
    80002690:	6402                	ld	s0,0(sp)
    80002692:	0141                	addi	sp,sp,16
    80002694:	8082                	ret

0000000080002696 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002696:	1141                	addi	sp,sp,-16
    80002698:	e422                	sd	s0,8(sp)
    8000269a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269c:	00003797          	auipc	a5,0x3
    800026a0:	55478793          	addi	a5,a5,1364 # 80005bf0 <kernelvec>
    800026a4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026a8:	6422                	ld	s0,8(sp)
    800026aa:	0141                	addi	sp,sp,16
    800026ac:	8082                	ret

00000000800026ae <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ae:	1141                	addi	sp,sp,-16
    800026b0:	e406                	sd	ra,8(sp)
    800026b2:	e022                	sd	s0,0(sp)
    800026b4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	382080e7          	jalr	898(ra) # 80001a38 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026c8:	00005617          	auipc	a2,0x5
    800026cc:	93860613          	addi	a2,a2,-1736 # 80007000 <_trampoline>
    800026d0:	00005697          	auipc	a3,0x5
    800026d4:	93068693          	addi	a3,a3,-1744 # 80007000 <_trampoline>
    800026d8:	8e91                	sub	a3,a3,a2
    800026da:	040007b7          	lui	a5,0x4000
    800026de:	17fd                	addi	a5,a5,-1
    800026e0:	07b2                	slli	a5,a5,0xc
    800026e2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026e8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ea:	180026f3          	csrr	a3,satp
    800026ee:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f0:	6d38                	ld	a4,88(a0)
    800026f2:	6134                	ld	a3,64(a0)
    800026f4:	6585                	lui	a1,0x1
    800026f6:	96ae                	add	a3,a3,a1
    800026f8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026fa:	6d38                	ld	a4,88(a0)
    800026fc:	00000697          	auipc	a3,0x0
    80002700:	13868693          	addi	a3,a3,312 # 80002834 <usertrap>
    80002704:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002706:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002708:	8692                	mv	a3,tp
    8000270a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002710:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002714:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002718:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000271c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000271e:	6f18                	ld	a4,24(a4)
    80002720:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002724:	692c                	ld	a1,80(a0)
    80002726:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002728:	00005717          	auipc	a4,0x5
    8000272c:	96870713          	addi	a4,a4,-1688 # 80007090 <userret>
    80002730:	8f11                	sub	a4,a4,a2
    80002732:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002734:	577d                	li	a4,-1
    80002736:	177e                	slli	a4,a4,0x3f
    80002738:	8dd9                	or	a1,a1,a4
    8000273a:	02000537          	lui	a0,0x2000
    8000273e:	157d                	addi	a0,a0,-1
    80002740:	0536                	slli	a0,a0,0xd
    80002742:	9782                	jalr	a5
}
    80002744:	60a2                	ld	ra,8(sp)
    80002746:	6402                	ld	s0,0(sp)
    80002748:	0141                	addi	sp,sp,16
    8000274a:	8082                	ret

000000008000274c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000274c:	1101                	addi	sp,sp,-32
    8000274e:	ec06                	sd	ra,24(sp)
    80002750:	e822                	sd	s0,16(sp)
    80002752:	e426                	sd	s1,8(sp)
    80002754:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002756:	00015497          	auipc	s1,0x15
    8000275a:	01248493          	addi	s1,s1,18 # 80017768 <tickslock>
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	4b0080e7          	jalr	1200(ra) # 80000c10 <acquire>
  ticks++;
    80002768:	00007517          	auipc	a0,0x7
    8000276c:	8b850513          	addi	a0,a0,-1864 # 80009020 <ticks>
    80002770:	411c                	lw	a5,0(a0)
    80002772:	2785                	addiw	a5,a5,1
    80002774:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002776:	00000097          	auipc	ra,0x0
    8000277a:	c58080e7          	jalr	-936(ra) # 800023ce <wakeup>
  release(&tickslock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	544080e7          	jalr	1348(ra) # 80000cc4 <release>
}
    80002788:	60e2                	ld	ra,24(sp)
    8000278a:	6442                	ld	s0,16(sp)
    8000278c:	64a2                	ld	s1,8(sp)
    8000278e:	6105                	addi	sp,sp,32
    80002790:	8082                	ret

0000000080002792 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002792:	1101                	addi	sp,sp,-32
    80002794:	ec06                	sd	ra,24(sp)
    80002796:	e822                	sd	s0,16(sp)
    80002798:	e426                	sd	s1,8(sp)
    8000279a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027a0:	00074d63          	bltz	a4,800027ba <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027a4:	57fd                	li	a5,-1
    800027a6:	17fe                	slli	a5,a5,0x3f
    800027a8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027aa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ac:	06f70363          	beq	a4,a5,80002812 <devintr+0x80>
  }
}
    800027b0:	60e2                	ld	ra,24(sp)
    800027b2:	6442                	ld	s0,16(sp)
    800027b4:	64a2                	ld	s1,8(sp)
    800027b6:	6105                	addi	sp,sp,32
    800027b8:	8082                	ret
     (scause & 0xff) == 9){
    800027ba:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027be:	46a5                	li	a3,9
    800027c0:	fed792e3          	bne	a5,a3,800027a4 <devintr+0x12>
    int irq = plic_claim();
    800027c4:	00003097          	auipc	ra,0x3
    800027c8:	534080e7          	jalr	1332(ra) # 80005cf8 <plic_claim>
    800027cc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027ce:	47a9                	li	a5,10
    800027d0:	02f50763          	beq	a0,a5,800027fe <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027d4:	4785                	li	a5,1
    800027d6:	02f50963          	beq	a0,a5,80002808 <devintr+0x76>
    return 1;
    800027da:	4505                	li	a0,1
    } else if(irq){
    800027dc:	d8f1                	beqz	s1,800027b0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027de:	85a6                	mv	a1,s1
    800027e0:	00006517          	auipc	a0,0x6
    800027e4:	a9050513          	addi	a0,a0,-1392 # 80008270 <states.1702+0x30>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	daa080e7          	jalr	-598(ra) # 80000592 <printf>
      plic_complete(irq);
    800027f0:	8526                	mv	a0,s1
    800027f2:	00003097          	auipc	ra,0x3
    800027f6:	52a080e7          	jalr	1322(ra) # 80005d1c <plic_complete>
    return 1;
    800027fa:	4505                	li	a0,1
    800027fc:	bf55                	j	800027b0 <devintr+0x1e>
      uartintr();
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	1d6080e7          	jalr	470(ra) # 800009d4 <uartintr>
    80002806:	b7ed                	j	800027f0 <devintr+0x5e>
      virtio_disk_intr();
    80002808:	00004097          	auipc	ra,0x4
    8000280c:	9ae080e7          	jalr	-1618(ra) # 800061b6 <virtio_disk_intr>
    80002810:	b7c5                	j	800027f0 <devintr+0x5e>
    if(cpuid() == 0){
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	1fa080e7          	jalr	506(ra) # 80001a0c <cpuid>
    8000281a:	c901                	beqz	a0,8000282a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000281c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002820:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002822:	14479073          	csrw	sip,a5
    return 2;
    80002826:	4509                	li	a0,2
    80002828:	b761                	j	800027b0 <devintr+0x1e>
      clockintr();
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	f22080e7          	jalr	-222(ra) # 8000274c <clockintr>
    80002832:	b7ed                	j	8000281c <devintr+0x8a>

0000000080002834 <usertrap>:
{
    80002834:	7179                	addi	sp,sp,-48
    80002836:	f406                	sd	ra,40(sp)
    80002838:	f022                	sd	s0,32(sp)
    8000283a:	ec26                	sd	s1,24(sp)
    8000283c:	e84a                	sd	s2,16(sp)
    8000283e:	e44e                	sd	s3,8(sp)
    80002840:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002842:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002846:	1007f793          	andi	a5,a5,256
    8000284a:	e3c1                	bnez	a5,800028ca <usertrap+0x96>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284c:	00003797          	auipc	a5,0x3
    80002850:	3a478793          	addi	a5,a5,932 # 80005bf0 <kernelvec>
    80002854:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	1e0080e7          	jalr	480(ra) # 80001a38 <myproc>
    80002860:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002862:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002864:	14102773          	csrr	a4,sepc
    80002868:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000286a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000286e:	47a1                	li	a5,8
    80002870:	06f70563          	beq	a4,a5,800028da <usertrap+0xa6>
    80002874:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15) {
    80002878:	47b5                	li	a5,13
    8000287a:	00f70763          	beq	a4,a5,80002888 <usertrap+0x54>
    8000287e:	14202773          	csrr	a4,scause
    80002882:	47bd                	li	a5,15
    80002884:	0cf71863          	bne	a4,a5,80002954 <usertrap+0x120>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002888:	14302973          	csrr	s2,stval
    if(pagefault_va < p->sz && pagefault_va >= PGROUNDDOWN(p->trapframe->sp)) {
    8000288c:	64bc                	ld	a5,72(s1)
    8000288e:	00f97863          	bgeu	s2,a5,8000289e <usertrap+0x6a>
    80002892:	6cbc                	ld	a5,88(s1)
    80002894:	7b98                	ld	a4,48(a5)
    80002896:	77fd                	lui	a5,0xfffff
    80002898:	8ff9                	and	a5,a5,a4
    8000289a:	06f97a63          	bgeu	s2,a5,8000290e <usertrap+0xda>
      p->killed = 1;
    8000289e:	4785                	li	a5,1
    800028a0:	d89c                	sw	a5,48(s1)
{
    800028a2:	4901                	li	s2,0
    exit(-1);
    800028a4:	557d                	li	a0,-1
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	85c080e7          	jalr	-1956(ra) # 80002102 <exit>
  if(which_dev == 2)
    800028ae:	4789                	li	a5,2
    800028b0:	0ef90563          	beq	s2,a5,8000299a <usertrap+0x166>
  usertrapret();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	dfa080e7          	jalr	-518(ra) # 800026ae <usertrapret>
}
    800028bc:	70a2                	ld	ra,40(sp)
    800028be:	7402                	ld	s0,32(sp)
    800028c0:	64e2                	ld	s1,24(sp)
    800028c2:	6942                	ld	s2,16(sp)
    800028c4:	69a2                	ld	s3,8(sp)
    800028c6:	6145                	addi	sp,sp,48
    800028c8:	8082                	ret
    panic("usertrap: not from user mode");
    800028ca:	00006517          	auipc	a0,0x6
    800028ce:	9c650513          	addi	a0,a0,-1594 # 80008290 <states.1702+0x50>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	c76080e7          	jalr	-906(ra) # 80000548 <panic>
    if(p->killed)
    800028da:	591c                	lw	a5,48(a0)
    800028dc:	e39d                	bnez	a5,80002902 <usertrap+0xce>
    p->trapframe->epc += 4;
    800028de:	6cb8                	ld	a4,88(s1)
    800028e0:	6f1c                	ld	a5,24(a4)
    800028e2:	0791                	addi	a5,a5,4
    800028e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ee:	10079073          	csrw	sstatus,a5
    syscall();
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	2f4080e7          	jalr	756(ra) # 80002be6 <syscall>
  if(p->killed)
    800028fa:	589c                	lw	a5,48(s1)
    800028fc:	dfc5                	beqz	a5,800028b4 <usertrap+0x80>
    800028fe:	4901                	li	s2,0
    80002900:	b755                	j	800028a4 <usertrap+0x70>
      exit(-1);
    80002902:	557d                	li	a0,-1
    80002904:	fffff097          	auipc	ra,0xfffff
    80002908:	7fe080e7          	jalr	2046(ra) # 80002102 <exit>
    8000290c:	bfc9                	j	800028de <usertrap+0xaa>
      char* mem = kalloc();
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	212080e7          	jalr	530(ra) # 80000b20 <kalloc>
    80002916:	89aa                	mv	s3,a0
      if(mem == 0) {
    80002918:	c91d                	beqz	a0,8000294e <usertrap+0x11a>
        memset(mem, 0, PGSIZE);
    8000291a:	6605                	lui	a2,0x1
    8000291c:	4581                	li	a1,0
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	3ee080e7          	jalr	1006(ra) # 80000d0c <memset>
        if(mappages(p->pagetable, pagefault_va, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_U | PTE_X) != 0) {
    80002926:	4779                	li	a4,30
    80002928:	86ce                	mv	a3,s3
    8000292a:	6605                	lui	a2,0x1
    8000292c:	75fd                	lui	a1,0xfffff
    8000292e:	00b975b3          	and	a1,s2,a1
    80002932:	68a8                	ld	a0,80(s1)
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	7c8080e7          	jalr	1992(ra) # 800010fc <mappages>
    8000293c:	dd5d                	beqz	a0,800028fa <usertrap+0xc6>
          kfree(mem);
    8000293e:	854e                	mv	a0,s3
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	0e4080e7          	jalr	228(ra) # 80000a24 <kfree>
          p->killed = 1;
    80002948:	4785                	li	a5,1
    8000294a:	d89c                	sw	a5,48(s1)
    8000294c:	bf99                	j	800028a2 <usertrap+0x6e>
        p->killed = 1;
    8000294e:	4785                	li	a5,1
    80002950:	d89c                	sw	a5,48(s1)
    80002952:	bf81                	j	800028a2 <usertrap+0x6e>
  } else if((which_dev = devintr()) != 0){
    80002954:	00000097          	auipc	ra,0x0
    80002958:	e3e080e7          	jalr	-450(ra) # 80002792 <devintr>
    8000295c:	892a                	mv	s2,a0
    8000295e:	c501                	beqz	a0,80002966 <usertrap+0x132>
  if(p->killed)
    80002960:	589c                	lw	a5,48(s1)
    80002962:	d7b1                	beqz	a5,800028ae <usertrap+0x7a>
    80002964:	b781                	j	800028a4 <usertrap+0x70>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002966:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000296a:	5c90                	lw	a2,56(s1)
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	94450513          	addi	a0,a0,-1724 # 800082b0 <states.1702+0x70>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	c1e080e7          	jalr	-994(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002980:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002984:	00006517          	auipc	a0,0x6
    80002988:	95c50513          	addi	a0,a0,-1700 # 800082e0 <states.1702+0xa0>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	c06080e7          	jalr	-1018(ra) # 80000592 <printf>
    p->killed = 1;
    80002994:	4785                	li	a5,1
    80002996:	d89c                	sw	a5,48(s1)
    80002998:	b729                	j	800028a2 <usertrap+0x6e>
    yield();
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	872080e7          	jalr	-1934(ra) # 8000220c <yield>
    800029a2:	bf09                	j	800028b4 <usertrap+0x80>

00000000800029a4 <kerneltrap>:
{
    800029a4:	7179                	addi	sp,sp,-48
    800029a6:	f406                	sd	ra,40(sp)
    800029a8:	f022                	sd	s0,32(sp)
    800029aa:	ec26                	sd	s1,24(sp)
    800029ac:	e84a                	sd	s2,16(sp)
    800029ae:	e44e                	sd	s3,8(sp)
    800029b0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029be:	1004f793          	andi	a5,s1,256
    800029c2:	cb85                	beqz	a5,800029f2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ca:	ef85                	bnez	a5,80002a02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029cc:	00000097          	auipc	ra,0x0
    800029d0:	dc6080e7          	jalr	-570(ra) # 80002792 <devintr>
    800029d4:	cd1d                	beqz	a0,80002a12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d6:	4789                	li	a5,2
    800029d8:	06f50a63          	beq	a0,a5,80002a4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029dc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e0:	10049073          	csrw	sstatus,s1
}
    800029e4:	70a2                	ld	ra,40(sp)
    800029e6:	7402                	ld	s0,32(sp)
    800029e8:	64e2                	ld	s1,24(sp)
    800029ea:	6942                	ld	s2,16(sp)
    800029ec:	69a2                	ld	s3,8(sp)
    800029ee:	6145                	addi	sp,sp,48
    800029f0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	90e50513          	addi	a0,a0,-1778 # 80008300 <states.1702+0xc0>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b4e080e7          	jalr	-1202(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	92650513          	addi	a0,a0,-1754 # 80008328 <states.1702+0xe8>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b3e080e7          	jalr	-1218(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a12:	85ce                	mv	a1,s3
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	93450513          	addi	a0,a0,-1740 # 80008348 <states.1702+0x108>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b76080e7          	jalr	-1162(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	92c50513          	addi	a0,a0,-1748 # 80008358 <states.1702+0x118>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b5e080e7          	jalr	-1186(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	93450513          	addi	a0,a0,-1740 # 80008370 <states.1702+0x130>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b04080e7          	jalr	-1276(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	fec080e7          	jalr	-20(ra) # 80001a38 <myproc>
    80002a54:	d541                	beqz	a0,800029dc <kerneltrap+0x38>
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	fe2080e7          	jalr	-30(ra) # 80001a38 <myproc>
    80002a5e:	4d18                	lw	a4,24(a0)
    80002a60:	478d                	li	a5,3
    80002a62:	f6f71de3          	bne	a4,a5,800029dc <kerneltrap+0x38>
    yield();
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	7a6080e7          	jalr	1958(ra) # 8000220c <yield>
    80002a6e:	b7bd                	j	800029dc <kerneltrap+0x38>

0000000080002a70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	fbc080e7          	jalr	-68(ra) # 80001a38 <myproc>
  switch (n) {
    80002a84:	4795                	li	a5,5
    80002a86:	0497e163          	bltu	a5,s1,80002ac8 <argraw+0x58>
    80002a8a:	048a                	slli	s1,s1,0x2
    80002a8c:	00006717          	auipc	a4,0x6
    80002a90:	91c70713          	addi	a4,a4,-1764 # 800083a8 <states.1702+0x168>
    80002a94:	94ba                	add	s1,s1,a4
    80002a96:	409c                	lw	a5,0(s1)
    80002a98:	97ba                	add	a5,a5,a4
    80002a9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aa0:	60e2                	ld	ra,24(sp)
    80002aa2:	6442                	ld	s0,16(sp)
    80002aa4:	64a2                	ld	s1,8(sp)
    80002aa6:	6105                	addi	sp,sp,32
    80002aa8:	8082                	ret
    return p->trapframe->a1;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	7fa8                	ld	a0,120(a5)
    80002aae:	bfcd                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a2;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	63c8                	ld	a0,128(a5)
    80002ab4:	b7f5                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a3;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	67c8                	ld	a0,136(a5)
    80002aba:	b7dd                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a4;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	6bc8                	ld	a0,144(a5)
    80002ac0:	b7c5                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a5;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	6fc8                	ld	a0,152(a5)
    80002ac6:	bfe9                	j	80002aa0 <argraw+0x30>
  panic("argraw");
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	8b850513          	addi	a0,a0,-1864 # 80008380 <states.1702+0x140>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	a78080e7          	jalr	-1416(ra) # 80000548 <panic>

0000000080002ad8 <fetchaddr>:
{
    80002ad8:	1101                	addi	sp,sp,-32
    80002ada:	ec06                	sd	ra,24(sp)
    80002adc:	e822                	sd	s0,16(sp)
    80002ade:	e426                	sd	s1,8(sp)
    80002ae0:	e04a                	sd	s2,0(sp)
    80002ae2:	1000                	addi	s0,sp,32
    80002ae4:	84aa                	mv	s1,a0
    80002ae6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	f50080e7          	jalr	-176(ra) # 80001a38 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002af0:	653c                	ld	a5,72(a0)
    80002af2:	02f4f863          	bgeu	s1,a5,80002b22 <fetchaddr+0x4a>
    80002af6:	00848713          	addi	a4,s1,8
    80002afa:	02e7e663          	bltu	a5,a4,80002b26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002afe:	46a1                	li	a3,8
    80002b00:	8626                	mv	a2,s1
    80002b02:	85ca                	mv	a1,s2
    80002b04:	6928                	ld	a0,80(a0)
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	cb2080e7          	jalr	-846(ra) # 800017b8 <copyin>
    80002b0e:	00a03533          	snez	a0,a0
    80002b12:	40a00533          	neg	a0,a0
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6902                	ld	s2,0(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret
    return -1;
    80002b22:	557d                	li	a0,-1
    80002b24:	bfcd                	j	80002b16 <fetchaddr+0x3e>
    80002b26:	557d                	li	a0,-1
    80002b28:	b7fd                	j	80002b16 <fetchaddr+0x3e>

0000000080002b2a <fetchstr>:
{
    80002b2a:	7179                	addi	sp,sp,-48
    80002b2c:	f406                	sd	ra,40(sp)
    80002b2e:	f022                	sd	s0,32(sp)
    80002b30:	ec26                	sd	s1,24(sp)
    80002b32:	e84a                	sd	s2,16(sp)
    80002b34:	e44e                	sd	s3,8(sp)
    80002b36:	1800                	addi	s0,sp,48
    80002b38:	892a                	mv	s2,a0
    80002b3a:	84ae                	mv	s1,a1
    80002b3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	efa080e7          	jalr	-262(ra) # 80001a38 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b46:	86ce                	mv	a3,s3
    80002b48:	864a                	mv	a2,s2
    80002b4a:	85a6                	mv	a1,s1
    80002b4c:	6928                	ld	a0,80(a0)
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	cf6080e7          	jalr	-778(ra) # 80001844 <copyinstr>
  if(err < 0)
    80002b56:	00054763          	bltz	a0,80002b64 <fetchstr+0x3a>
  return strlen(buf);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	338080e7          	jalr	824(ra) # 80000e94 <strlen>
}
    80002b64:	70a2                	ld	ra,40(sp)
    80002b66:	7402                	ld	s0,32(sp)
    80002b68:	64e2                	ld	s1,24(sp)
    80002b6a:	6942                	ld	s2,16(sp)
    80002b6c:	69a2                	ld	s3,8(sp)
    80002b6e:	6145                	addi	sp,sp,48
    80002b70:	8082                	ret

0000000080002b72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	1000                	addi	s0,sp,32
    80002b7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	ef2080e7          	jalr	-270(ra) # 80002a70 <argraw>
    80002b86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b88:	4501                	li	a0,0
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret

0000000080002b94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b94:	1101                	addi	sp,sp,-32
    80002b96:	ec06                	sd	ra,24(sp)
    80002b98:	e822                	sd	s0,16(sp)
    80002b9a:	e426                	sd	s1,8(sp)
    80002b9c:	1000                	addi	s0,sp,32
    80002b9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	ed0080e7          	jalr	-304(ra) # 80002a70 <argraw>
    80002ba8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002baa:	4501                	li	a0,0
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	64a2                	ld	s1,8(sp)
    80002bb2:	6105                	addi	sp,sp,32
    80002bb4:	8082                	ret

0000000080002bb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
    80002bc2:	84ae                	mv	s1,a1
    80002bc4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	eaa080e7          	jalr	-342(ra) # 80002a70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bce:	864a                	mv	a2,s2
    80002bd0:	85a6                	mv	a1,s1
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	f58080e7          	jalr	-168(ra) # 80002b2a <fetchstr>
}
    80002bda:	60e2                	ld	ra,24(sp)
    80002bdc:	6442                	ld	s0,16(sp)
    80002bde:	64a2                	ld	s1,8(sp)
    80002be0:	6902                	ld	s2,0(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	e426                	sd	s1,8(sp)
    80002bee:	e04a                	sd	s2,0(sp)
    80002bf0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	e46080e7          	jalr	-442(ra) # 80001a38 <myproc>
    80002bfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfc:	05853903          	ld	s2,88(a0)
    80002c00:	0a893783          	ld	a5,168(s2)
    80002c04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c08:	37fd                	addiw	a5,a5,-1
    80002c0a:	4751                	li	a4,20
    80002c0c:	00f76f63          	bltu	a4,a5,80002c2a <syscall+0x44>
    80002c10:	00369713          	slli	a4,a3,0x3
    80002c14:	00005797          	auipc	a5,0x5
    80002c18:	7ac78793          	addi	a5,a5,1964 # 800083c0 <syscalls>
    80002c1c:	97ba                	add	a5,a5,a4
    80002c1e:	639c                	ld	a5,0(a5)
    80002c20:	c789                	beqz	a5,80002c2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c22:	9782                	jalr	a5
    80002c24:	06a93823          	sd	a0,112(s2)
    80002c28:	a839                	j	80002c46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c2a:	15848613          	addi	a2,s1,344
    80002c2e:	5c8c                	lw	a1,56(s1)
    80002c30:	00005517          	auipc	a0,0x5
    80002c34:	75850513          	addi	a0,a0,1880 # 80008388 <states.1702+0x148>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	95a080e7          	jalr	-1702(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c40:	6cbc                	ld	a5,88(s1)
    80002c42:	577d                	li	a4,-1
    80002c44:	fbb8                	sd	a4,112(a5)
  }
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6902                	ld	s2,0(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret

0000000080002c52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c52:	1101                	addi	sp,sp,-32
    80002c54:	ec06                	sd	ra,24(sp)
    80002c56:	e822                	sd	s0,16(sp)
    80002c58:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c5a:	fec40593          	addi	a1,s0,-20
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	f12080e7          	jalr	-238(ra) # 80002b72 <argint>
    return -1;
    80002c68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c6a:	00054963          	bltz	a0,80002c7c <sys_exit+0x2a>
  exit(n);
    80002c6e:	fec42503          	lw	a0,-20(s0)
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	490080e7          	jalr	1168(ra) # 80002102 <exit>
  return 0;  // not reached
    80002c7a:	4781                	li	a5,0
}
    80002c7c:	853e                	mv	a0,a5
    80002c7e:	60e2                	ld	ra,24(sp)
    80002c80:	6442                	ld	s0,16(sp)
    80002c82:	6105                	addi	sp,sp,32
    80002c84:	8082                	ret

0000000080002c86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	daa080e7          	jalr	-598(ra) # 80001a38 <myproc>
}
    80002c96:	5d08                	lw	a0,56(a0)
    80002c98:	60a2                	ld	ra,8(sp)
    80002c9a:	6402                	ld	s0,0(sp)
    80002c9c:	0141                	addi	sp,sp,16
    80002c9e:	8082                	ret

0000000080002ca0 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca0:	1141                	addi	sp,sp,-16
    80002ca2:	e406                	sd	ra,8(sp)
    80002ca4:	e022                	sd	s0,0(sp)
    80002ca6:	0800                	addi	s0,sp,16
  return fork();
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	150080e7          	jalr	336(ra) # 80001df8 <fork>
}
    80002cb0:	60a2                	ld	ra,8(sp)
    80002cb2:	6402                	ld	s0,0(sp)
    80002cb4:	0141                	addi	sp,sp,16
    80002cb6:	8082                	ret

0000000080002cb8 <sys_wait>:

uint64
sys_wait(void)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cc0:	fe840593          	addi	a1,s0,-24
    80002cc4:	4501                	li	a0,0
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	ece080e7          	jalr	-306(ra) # 80002b94 <argaddr>
    80002cce:	87aa                	mv	a5,a0
    return -1;
    80002cd0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cd2:	0007c863          	bltz	a5,80002ce2 <sys_wait+0x2a>
  return wait(p);
    80002cd6:	fe843503          	ld	a0,-24(s0)
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	5ec080e7          	jalr	1516(ra) # 800022c6 <wait>
}
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cea:	7179                	addi	sp,sp,-48
    80002cec:	f406                	sd	ra,40(sp)
    80002cee:	f022                	sd	s0,32(sp)
    80002cf0:	ec26                	sd	s1,24(sp)
    80002cf2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cf4:	fdc40593          	addi	a1,s0,-36
    80002cf8:	4501                	li	a0,0
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	e78080e7          	jalr	-392(ra) # 80002b72 <argint>
    80002d02:	87aa                	mv	a5,a0
    return -1;
    80002d04:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d06:	0207c163          	bltz	a5,80002d28 <sys_sbrk+0x3e>

  struct proc* p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	d2e080e7          	jalr	-722(ra) # 80001a38 <myproc>
  addr = p->sz;
    80002d12:	652c                	ld	a1,72(a0)
    80002d14:	0005849b          	sext.w	s1,a1
  p->sz += n;
    80002d18:	fdc42783          	lw	a5,-36(s0)
    80002d1c:	00b78633          	add	a2,a5,a1
    80002d20:	e530                	sd	a2,72(a0)

  // if(growproc(n) < 0)
  //   return -1;
  if (n < 0) {
    80002d22:	0007c863          	bltz	a5,80002d32 <sys_sbrk+0x48>
    uvmdealloc(p->pagetable, p->sz - n, p->sz);
  }

  return addr;
    80002d26:	8526                	mv	a0,s1
}
    80002d28:	70a2                	ld	ra,40(sp)
    80002d2a:	7402                	ld	s0,32(sp)
    80002d2c:	64e2                	ld	s1,24(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret
    uvmdealloc(p->pagetable, p->sz - n, p->sz);
    80002d32:	6928                	ld	a0,80(a0)
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	77c080e7          	jalr	1916(ra) # 800014b0 <uvmdealloc>
    80002d3c:	b7ed                	j	80002d26 <sys_sbrk+0x3c>

0000000080002d3e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d3e:	7139                	addi	sp,sp,-64
    80002d40:	fc06                	sd	ra,56(sp)
    80002d42:	f822                	sd	s0,48(sp)
    80002d44:	f426                	sd	s1,40(sp)
    80002d46:	f04a                	sd	s2,32(sp)
    80002d48:	ec4e                	sd	s3,24(sp)
    80002d4a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d4c:	fcc40593          	addi	a1,s0,-52
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	e20080e7          	jalr	-480(ra) # 80002b72 <argint>
    return -1;
    80002d5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5c:	06054563          	bltz	a0,80002dc6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d60:	00015517          	auipc	a0,0x15
    80002d64:	a0850513          	addi	a0,a0,-1528 # 80017768 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	ea8080e7          	jalr	-344(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002d70:	00006917          	auipc	s2,0x6
    80002d74:	2b092903          	lw	s2,688(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d78:	fcc42783          	lw	a5,-52(s0)
    80002d7c:	cf85                	beqz	a5,80002db4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d7e:	00015997          	auipc	s3,0x15
    80002d82:	9ea98993          	addi	s3,s3,-1558 # 80017768 <tickslock>
    80002d86:	00006497          	auipc	s1,0x6
    80002d8a:	29a48493          	addi	s1,s1,666 # 80009020 <ticks>
    if(myproc()->killed){
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	caa080e7          	jalr	-854(ra) # 80001a38 <myproc>
    80002d96:	591c                	lw	a5,48(a0)
    80002d98:	ef9d                	bnez	a5,80002dd6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d9a:	85ce                	mv	a1,s3
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	4aa080e7          	jalr	1194(ra) # 80002248 <sleep>
  while(ticks - ticks0 < n){
    80002da6:	409c                	lw	a5,0(s1)
    80002da8:	412787bb          	subw	a5,a5,s2
    80002dac:	fcc42703          	lw	a4,-52(s0)
    80002db0:	fce7efe3          	bltu	a5,a4,80002d8e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db4:	00015517          	auipc	a0,0x15
    80002db8:	9b450513          	addi	a0,a0,-1612 # 80017768 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	f08080e7          	jalr	-248(ra) # 80000cc4 <release>
  return 0;
    80002dc4:	4781                	li	a5,0
}
    80002dc6:	853e                	mv	a0,a5
    80002dc8:	70e2                	ld	ra,56(sp)
    80002dca:	7442                	ld	s0,48(sp)
    80002dcc:	74a2                	ld	s1,40(sp)
    80002dce:	7902                	ld	s2,32(sp)
    80002dd0:	69e2                	ld	s3,24(sp)
    80002dd2:	6121                	addi	sp,sp,64
    80002dd4:	8082                	ret
      release(&tickslock);
    80002dd6:	00015517          	auipc	a0,0x15
    80002dda:	99250513          	addi	a0,a0,-1646 # 80017768 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	ee6080e7          	jalr	-282(ra) # 80000cc4 <release>
      return -1;
    80002de6:	57fd                	li	a5,-1
    80002de8:	bff9                	j	80002dc6 <sys_sleep+0x88>

0000000080002dea <sys_kill>:

uint64
sys_kill(void)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df2:	fec40593          	addi	a1,s0,-20
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	d7a080e7          	jalr	-646(ra) # 80002b72 <argint>
    80002e00:	87aa                	mv	a5,a0
    return -1;
    80002e02:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e04:	0007c863          	bltz	a5,80002e14 <sys_kill+0x2a>
  return kill(pid);
    80002e08:	fec42503          	lw	a0,-20(s0)
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	62c080e7          	jalr	1580(ra) # 80002438 <kill>
}
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e26:	00015517          	auipc	a0,0x15
    80002e2a:	94250513          	addi	a0,a0,-1726 # 80017768 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	de2080e7          	jalr	-542(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e36:	00006497          	auipc	s1,0x6
    80002e3a:	1ea4a483          	lw	s1,490(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e3e:	00015517          	auipc	a0,0x15
    80002e42:	92a50513          	addi	a0,a0,-1750 # 80017768 <tickslock>
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	e7e080e7          	jalr	-386(ra) # 80000cc4 <release>
  return xticks;
}
    80002e4e:	02049513          	slli	a0,s1,0x20
    80002e52:	9101                	srli	a0,a0,0x20
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e5e:	7179                	addi	sp,sp,-48
    80002e60:	f406                	sd	ra,40(sp)
    80002e62:	f022                	sd	s0,32(sp)
    80002e64:	ec26                	sd	s1,24(sp)
    80002e66:	e84a                	sd	s2,16(sp)
    80002e68:	e44e                	sd	s3,8(sp)
    80002e6a:	e052                	sd	s4,0(sp)
    80002e6c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e6e:	00005597          	auipc	a1,0x5
    80002e72:	60258593          	addi	a1,a1,1538 # 80008470 <syscalls+0xb0>
    80002e76:	00015517          	auipc	a0,0x15
    80002e7a:	90a50513          	addi	a0,a0,-1782 # 80017780 <bcache>
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	d02080e7          	jalr	-766(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e86:	0001d797          	auipc	a5,0x1d
    80002e8a:	8fa78793          	addi	a5,a5,-1798 # 8001f780 <bcache+0x8000>
    80002e8e:	0001d717          	auipc	a4,0x1d
    80002e92:	b5a70713          	addi	a4,a4,-1190 # 8001f9e8 <bcache+0x8268>
    80002e96:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e9a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e9e:	00015497          	auipc	s1,0x15
    80002ea2:	8fa48493          	addi	s1,s1,-1798 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ea6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ea8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eaa:	00005a17          	auipc	s4,0x5
    80002eae:	5cea0a13          	addi	s4,s4,1486 # 80008478 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eb2:	2b893783          	ld	a5,696(s2)
    80002eb6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eb8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ebc:	85d2                	mv	a1,s4
    80002ebe:	01048513          	addi	a0,s1,16
    80002ec2:	00001097          	auipc	ra,0x1
    80002ec6:	4b0080e7          	jalr	1200(ra) # 80004372 <initsleeplock>
    bcache.head.next->prev = b;
    80002eca:	2b893783          	ld	a5,696(s2)
    80002ece:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ed0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed4:	45848493          	addi	s1,s1,1112
    80002ed8:	fd349de3          	bne	s1,s3,80002eb2 <binit+0x54>
  }
}
    80002edc:	70a2                	ld	ra,40(sp)
    80002ede:	7402                	ld	s0,32(sp)
    80002ee0:	64e2                	ld	s1,24(sp)
    80002ee2:	6942                	ld	s2,16(sp)
    80002ee4:	69a2                	ld	s3,8(sp)
    80002ee6:	6a02                	ld	s4,0(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret

0000000080002eec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	1800                	addi	s0,sp,48
    80002efa:	89aa                	mv	s3,a0
    80002efc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002efe:	00015517          	auipc	a0,0x15
    80002f02:	88250513          	addi	a0,a0,-1918 # 80017780 <bcache>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	d0a080e7          	jalr	-758(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f0e:	0001d497          	auipc	s1,0x1d
    80002f12:	b2a4b483          	ld	s1,-1238(s1) # 8001fa38 <bcache+0x82b8>
    80002f16:	0001d797          	auipc	a5,0x1d
    80002f1a:	ad278793          	addi	a5,a5,-1326 # 8001f9e8 <bcache+0x8268>
    80002f1e:	02f48f63          	beq	s1,a5,80002f5c <bread+0x70>
    80002f22:	873e                	mv	a4,a5
    80002f24:	a021                	j	80002f2c <bread+0x40>
    80002f26:	68a4                	ld	s1,80(s1)
    80002f28:	02e48a63          	beq	s1,a4,80002f5c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f2c:	449c                	lw	a5,8(s1)
    80002f2e:	ff379ce3          	bne	a5,s3,80002f26 <bread+0x3a>
    80002f32:	44dc                	lw	a5,12(s1)
    80002f34:	ff2799e3          	bne	a5,s2,80002f26 <bread+0x3a>
      b->refcnt++;
    80002f38:	40bc                	lw	a5,64(s1)
    80002f3a:	2785                	addiw	a5,a5,1
    80002f3c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f3e:	00015517          	auipc	a0,0x15
    80002f42:	84250513          	addi	a0,a0,-1982 # 80017780 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	d7e080e7          	jalr	-642(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f4e:	01048513          	addi	a0,s1,16
    80002f52:	00001097          	auipc	ra,0x1
    80002f56:	45a080e7          	jalr	1114(ra) # 800043ac <acquiresleep>
      return b;
    80002f5a:	a8b9                	j	80002fb8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f5c:	0001d497          	auipc	s1,0x1d
    80002f60:	ad44b483          	ld	s1,-1324(s1) # 8001fa30 <bcache+0x82b0>
    80002f64:	0001d797          	auipc	a5,0x1d
    80002f68:	a8478793          	addi	a5,a5,-1404 # 8001f9e8 <bcache+0x8268>
    80002f6c:	00f48863          	beq	s1,a5,80002f7c <bread+0x90>
    80002f70:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f72:	40bc                	lw	a5,64(s1)
    80002f74:	cf81                	beqz	a5,80002f8c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f76:	64a4                	ld	s1,72(s1)
    80002f78:	fee49de3          	bne	s1,a4,80002f72 <bread+0x86>
  panic("bget: no buffers");
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	50450513          	addi	a0,a0,1284 # 80008480 <syscalls+0xc0>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	5c4080e7          	jalr	1476(ra) # 80000548 <panic>
      b->dev = dev;
    80002f8c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f90:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f94:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f98:	4785                	li	a5,1
    80002f9a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f9c:	00014517          	auipc	a0,0x14
    80002fa0:	7e450513          	addi	a0,a0,2020 # 80017780 <bcache>
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	d20080e7          	jalr	-736(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002fac:	01048513          	addi	a0,s1,16
    80002fb0:	00001097          	auipc	ra,0x1
    80002fb4:	3fc080e7          	jalr	1020(ra) # 800043ac <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fb8:	409c                	lw	a5,0(s1)
    80002fba:	cb89                	beqz	a5,80002fcc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fbc:	8526                	mv	a0,s1
    80002fbe:	70a2                	ld	ra,40(sp)
    80002fc0:	7402                	ld	s0,32(sp)
    80002fc2:	64e2                	ld	s1,24(sp)
    80002fc4:	6942                	ld	s2,16(sp)
    80002fc6:	69a2                	ld	s3,8(sp)
    80002fc8:	6145                	addi	sp,sp,48
    80002fca:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fcc:	4581                	li	a1,0
    80002fce:	8526                	mv	a0,s1
    80002fd0:	00003097          	auipc	ra,0x3
    80002fd4:	f3c080e7          	jalr	-196(ra) # 80005f0c <virtio_disk_rw>
    b->valid = 1;
    80002fd8:	4785                	li	a5,1
    80002fda:	c09c                	sw	a5,0(s1)
  return b;
    80002fdc:	b7c5                	j	80002fbc <bread+0xd0>

0000000080002fde <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fde:	1101                	addi	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	e426                	sd	s1,8(sp)
    80002fe6:	1000                	addi	s0,sp,32
    80002fe8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fea:	0541                	addi	a0,a0,16
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	45a080e7          	jalr	1114(ra) # 80004446 <holdingsleep>
    80002ff4:	cd01                	beqz	a0,8000300c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ff6:	4585                	li	a1,1
    80002ff8:	8526                	mv	a0,s1
    80002ffa:	00003097          	auipc	ra,0x3
    80002ffe:	f12080e7          	jalr	-238(ra) # 80005f0c <virtio_disk_rw>
}
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	64a2                	ld	s1,8(sp)
    80003008:	6105                	addi	sp,sp,32
    8000300a:	8082                	ret
    panic("bwrite");
    8000300c:	00005517          	auipc	a0,0x5
    80003010:	48c50513          	addi	a0,a0,1164 # 80008498 <syscalls+0xd8>
    80003014:	ffffd097          	auipc	ra,0xffffd
    80003018:	534080e7          	jalr	1332(ra) # 80000548 <panic>

000000008000301c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	e426                	sd	s1,8(sp)
    80003024:	e04a                	sd	s2,0(sp)
    80003026:	1000                	addi	s0,sp,32
    80003028:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000302a:	01050913          	addi	s2,a0,16
    8000302e:	854a                	mv	a0,s2
    80003030:	00001097          	auipc	ra,0x1
    80003034:	416080e7          	jalr	1046(ra) # 80004446 <holdingsleep>
    80003038:	c92d                	beqz	a0,800030aa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000303a:	854a                	mv	a0,s2
    8000303c:	00001097          	auipc	ra,0x1
    80003040:	3c6080e7          	jalr	966(ra) # 80004402 <releasesleep>

  acquire(&bcache.lock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	73c50513          	addi	a0,a0,1852 # 80017780 <bcache>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	bc4080e7          	jalr	-1084(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003054:	40bc                	lw	a5,64(s1)
    80003056:	37fd                	addiw	a5,a5,-1
    80003058:	0007871b          	sext.w	a4,a5
    8000305c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000305e:	eb05                	bnez	a4,8000308e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003060:	68bc                	ld	a5,80(s1)
    80003062:	64b8                	ld	a4,72(s1)
    80003064:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003066:	64bc                	ld	a5,72(s1)
    80003068:	68b8                	ld	a4,80(s1)
    8000306a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000306c:	0001c797          	auipc	a5,0x1c
    80003070:	71478793          	addi	a5,a5,1812 # 8001f780 <bcache+0x8000>
    80003074:	2b87b703          	ld	a4,696(a5)
    80003078:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000307a:	0001d717          	auipc	a4,0x1d
    8000307e:	96e70713          	addi	a4,a4,-1682 # 8001f9e8 <bcache+0x8268>
    80003082:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003084:	2b87b703          	ld	a4,696(a5)
    80003088:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000308a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	6f250513          	addi	a0,a0,1778 # 80017780 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	c2e080e7          	jalr	-978(ra) # 80000cc4 <release>
}
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	64a2                	ld	s1,8(sp)
    800030a4:	6902                	ld	s2,0(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret
    panic("brelse");
    800030aa:	00005517          	auipc	a0,0x5
    800030ae:	3f650513          	addi	a0,a0,1014 # 800084a0 <syscalls+0xe0>
    800030b2:	ffffd097          	auipc	ra,0xffffd
    800030b6:	496080e7          	jalr	1174(ra) # 80000548 <panic>

00000000800030ba <bpin>:

void
bpin(struct buf *b) {
    800030ba:	1101                	addi	sp,sp,-32
    800030bc:	ec06                	sd	ra,24(sp)
    800030be:	e822                	sd	s0,16(sp)
    800030c0:	e426                	sd	s1,8(sp)
    800030c2:	1000                	addi	s0,sp,32
    800030c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	6ba50513          	addi	a0,a0,1722 # 80017780 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	b42080e7          	jalr	-1214(ra) # 80000c10 <acquire>
  b->refcnt++;
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	2785                	addiw	a5,a5,1
    800030da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	6a450513          	addi	a0,a0,1700 # 80017780 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	be0080e7          	jalr	-1056(ra) # 80000cc4 <release>
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <bunpin>:

void
bunpin(struct buf *b) {
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003102:	00014517          	auipc	a0,0x14
    80003106:	67e50513          	addi	a0,a0,1662 # 80017780 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	b06080e7          	jalr	-1274(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003112:	40bc                	lw	a5,64(s1)
    80003114:	37fd                	addiw	a5,a5,-1
    80003116:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003118:	00014517          	auipc	a0,0x14
    8000311c:	66850513          	addi	a0,a0,1640 # 80017780 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	ba4080e7          	jalr	-1116(ra) # 80000cc4 <release>
}
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	e04a                	sd	s2,0(sp)
    8000313c:	1000                	addi	s0,sp,32
    8000313e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003140:	00d5d59b          	srliw	a1,a1,0xd
    80003144:	0001d797          	auipc	a5,0x1d
    80003148:	d187a783          	lw	a5,-744(a5) # 8001fe5c <sb+0x1c>
    8000314c:	9dbd                	addw	a1,a1,a5
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	d9e080e7          	jalr	-610(ra) # 80002eec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003156:	0074f713          	andi	a4,s1,7
    8000315a:	4785                	li	a5,1
    8000315c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003160:	14ce                	slli	s1,s1,0x33
    80003162:	90d9                	srli	s1,s1,0x36
    80003164:	00950733          	add	a4,a0,s1
    80003168:	05874703          	lbu	a4,88(a4)
    8000316c:	00e7f6b3          	and	a3,a5,a4
    80003170:	c69d                	beqz	a3,8000319e <bfree+0x6c>
    80003172:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003174:	94aa                	add	s1,s1,a0
    80003176:	fff7c793          	not	a5,a5
    8000317a:	8ff9                	and	a5,a5,a4
    8000317c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003180:	00001097          	auipc	ra,0x1
    80003184:	104080e7          	jalr	260(ra) # 80004284 <log_write>
  brelse(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	e92080e7          	jalr	-366(ra) # 8000301c <brelse>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6902                	ld	s2,0(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret
    panic("freeing free block");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	30a50513          	addi	a0,a0,778 # 800084a8 <syscalls+0xe8>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	3a2080e7          	jalr	930(ra) # 80000548 <panic>

00000000800031ae <balloc>:
{
    800031ae:	711d                	addi	sp,sp,-96
    800031b0:	ec86                	sd	ra,88(sp)
    800031b2:	e8a2                	sd	s0,80(sp)
    800031b4:	e4a6                	sd	s1,72(sp)
    800031b6:	e0ca                	sd	s2,64(sp)
    800031b8:	fc4e                	sd	s3,56(sp)
    800031ba:	f852                	sd	s4,48(sp)
    800031bc:	f456                	sd	s5,40(sp)
    800031be:	f05a                	sd	s6,32(sp)
    800031c0:	ec5e                	sd	s7,24(sp)
    800031c2:	e862                	sd	s8,16(sp)
    800031c4:	e466                	sd	s9,8(sp)
    800031c6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031c8:	0001d797          	auipc	a5,0x1d
    800031cc:	c7c7a783          	lw	a5,-900(a5) # 8001fe44 <sb+0x4>
    800031d0:	cbd1                	beqz	a5,80003264 <balloc+0xb6>
    800031d2:	8baa                	mv	s7,a0
    800031d4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031d6:	0001db17          	auipc	s6,0x1d
    800031da:	c6ab0b13          	addi	s6,s6,-918 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031de:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031e0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031e4:	6c89                	lui	s9,0x2
    800031e6:	a831                	j	80003202 <balloc+0x54>
    brelse(bp);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	e32080e7          	jalr	-462(ra) # 8000301c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031f2:	015c87bb          	addw	a5,s9,s5
    800031f6:	00078a9b          	sext.w	s5,a5
    800031fa:	004b2703          	lw	a4,4(s6)
    800031fe:	06eaf363          	bgeu	s5,a4,80003264 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003202:	41fad79b          	sraiw	a5,s5,0x1f
    80003206:	0137d79b          	srliw	a5,a5,0x13
    8000320a:	015787bb          	addw	a5,a5,s5
    8000320e:	40d7d79b          	sraiw	a5,a5,0xd
    80003212:	01cb2583          	lw	a1,28(s6)
    80003216:	9dbd                	addw	a1,a1,a5
    80003218:	855e                	mv	a0,s7
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	cd2080e7          	jalr	-814(ra) # 80002eec <bread>
    80003222:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003224:	004b2503          	lw	a0,4(s6)
    80003228:	000a849b          	sext.w	s1,s5
    8000322c:	8662                	mv	a2,s8
    8000322e:	faa4fde3          	bgeu	s1,a0,800031e8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003232:	41f6579b          	sraiw	a5,a2,0x1f
    80003236:	01d7d69b          	srliw	a3,a5,0x1d
    8000323a:	00c6873b          	addw	a4,a3,a2
    8000323e:	00777793          	andi	a5,a4,7
    80003242:	9f95                	subw	a5,a5,a3
    80003244:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003248:	4037571b          	sraiw	a4,a4,0x3
    8000324c:	00e906b3          	add	a3,s2,a4
    80003250:	0586c683          	lbu	a3,88(a3)
    80003254:	00d7f5b3          	and	a1,a5,a3
    80003258:	cd91                	beqz	a1,80003274 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325a:	2605                	addiw	a2,a2,1
    8000325c:	2485                	addiw	s1,s1,1
    8000325e:	fd4618e3          	bne	a2,s4,8000322e <balloc+0x80>
    80003262:	b759                	j	800031e8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003264:	00005517          	auipc	a0,0x5
    80003268:	25c50513          	addi	a0,a0,604 # 800084c0 <syscalls+0x100>
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	2dc080e7          	jalr	732(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003274:	974a                	add	a4,a4,s2
    80003276:	8fd5                	or	a5,a5,a3
    80003278:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	006080e7          	jalr	6(ra) # 80004284 <log_write>
        brelse(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	d94080e7          	jalr	-620(ra) # 8000301c <brelse>
  bp = bread(dev, bno);
    80003290:	85a6                	mv	a1,s1
    80003292:	855e                	mv	a0,s7
    80003294:	00000097          	auipc	ra,0x0
    80003298:	c58080e7          	jalr	-936(ra) # 80002eec <bread>
    8000329c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000329e:	40000613          	li	a2,1024
    800032a2:	4581                	li	a1,0
    800032a4:	05850513          	addi	a0,a0,88
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	a64080e7          	jalr	-1436(ra) # 80000d0c <memset>
  log_write(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00001097          	auipc	ra,0x1
    800032b6:	fd2080e7          	jalr	-46(ra) # 80004284 <log_write>
  brelse(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	d60080e7          	jalr	-672(ra) # 8000301c <brelse>
}
    800032c4:	8526                	mv	a0,s1
    800032c6:	60e6                	ld	ra,88(sp)
    800032c8:	6446                	ld	s0,80(sp)
    800032ca:	64a6                	ld	s1,72(sp)
    800032cc:	6906                	ld	s2,64(sp)
    800032ce:	79e2                	ld	s3,56(sp)
    800032d0:	7a42                	ld	s4,48(sp)
    800032d2:	7aa2                	ld	s5,40(sp)
    800032d4:	7b02                	ld	s6,32(sp)
    800032d6:	6be2                	ld	s7,24(sp)
    800032d8:	6c42                	ld	s8,16(sp)
    800032da:	6ca2                	ld	s9,8(sp)
    800032dc:	6125                	addi	sp,sp,96
    800032de:	8082                	ret

00000000800032e0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032e0:	7179                	addi	sp,sp,-48
    800032e2:	f406                	sd	ra,40(sp)
    800032e4:	f022                	sd	s0,32(sp)
    800032e6:	ec26                	sd	s1,24(sp)
    800032e8:	e84a                	sd	s2,16(sp)
    800032ea:	e44e                	sd	s3,8(sp)
    800032ec:	e052                	sd	s4,0(sp)
    800032ee:	1800                	addi	s0,sp,48
    800032f0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032f2:	47ad                	li	a5,11
    800032f4:	04b7fe63          	bgeu	a5,a1,80003350 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032f8:	ff45849b          	addiw	s1,a1,-12
    800032fc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003300:	0ff00793          	li	a5,255
    80003304:	0ae7e363          	bltu	a5,a4,800033aa <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003308:	08052583          	lw	a1,128(a0)
    8000330c:	c5ad                	beqz	a1,80003376 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000330e:	00092503          	lw	a0,0(s2)
    80003312:	00000097          	auipc	ra,0x0
    80003316:	bda080e7          	jalr	-1062(ra) # 80002eec <bread>
    8000331a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000331c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003320:	02049593          	slli	a1,s1,0x20
    80003324:	9181                	srli	a1,a1,0x20
    80003326:	058a                	slli	a1,a1,0x2
    80003328:	00b784b3          	add	s1,a5,a1
    8000332c:	0004a983          	lw	s3,0(s1)
    80003330:	04098d63          	beqz	s3,8000338a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003334:	8552                	mv	a0,s4
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	ce6080e7          	jalr	-794(ra) # 8000301c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000333e:	854e                	mv	a0,s3
    80003340:	70a2                	ld	ra,40(sp)
    80003342:	7402                	ld	s0,32(sp)
    80003344:	64e2                	ld	s1,24(sp)
    80003346:	6942                	ld	s2,16(sp)
    80003348:	69a2                	ld	s3,8(sp)
    8000334a:	6a02                	ld	s4,0(sp)
    8000334c:	6145                	addi	sp,sp,48
    8000334e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003350:	02059493          	slli	s1,a1,0x20
    80003354:	9081                	srli	s1,s1,0x20
    80003356:	048a                	slli	s1,s1,0x2
    80003358:	94aa                	add	s1,s1,a0
    8000335a:	0504a983          	lw	s3,80(s1)
    8000335e:	fe0990e3          	bnez	s3,8000333e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003362:	4108                	lw	a0,0(a0)
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e4a080e7          	jalr	-438(ra) # 800031ae <balloc>
    8000336c:	0005099b          	sext.w	s3,a0
    80003370:	0534a823          	sw	s3,80(s1)
    80003374:	b7e9                	j	8000333e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003376:	4108                	lw	a0,0(a0)
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	e36080e7          	jalr	-458(ra) # 800031ae <balloc>
    80003380:	0005059b          	sext.w	a1,a0
    80003384:	08b92023          	sw	a1,128(s2)
    80003388:	b759                	j	8000330e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000338a:	00092503          	lw	a0,0(s2)
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	e20080e7          	jalr	-480(ra) # 800031ae <balloc>
    80003396:	0005099b          	sext.w	s3,a0
    8000339a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000339e:	8552                	mv	a0,s4
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	ee4080e7          	jalr	-284(ra) # 80004284 <log_write>
    800033a8:	b771                	j	80003334 <bmap+0x54>
  panic("bmap: out of range");
    800033aa:	00005517          	auipc	a0,0x5
    800033ae:	12e50513          	addi	a0,a0,302 # 800084d8 <syscalls+0x118>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	196080e7          	jalr	406(ra) # 80000548 <panic>

00000000800033ba <iget>:
{
    800033ba:	7179                	addi	sp,sp,-48
    800033bc:	f406                	sd	ra,40(sp)
    800033be:	f022                	sd	s0,32(sp)
    800033c0:	ec26                	sd	s1,24(sp)
    800033c2:	e84a                	sd	s2,16(sp)
    800033c4:	e44e                	sd	s3,8(sp)
    800033c6:	e052                	sd	s4,0(sp)
    800033c8:	1800                	addi	s0,sp,48
    800033ca:	89aa                	mv	s3,a0
    800033cc:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033ce:	0001d517          	auipc	a0,0x1d
    800033d2:	a9250513          	addi	a0,a0,-1390 # 8001fe60 <icache>
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	83a080e7          	jalr	-1990(ra) # 80000c10 <acquire>
  empty = 0;
    800033de:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033e0:	0001d497          	auipc	s1,0x1d
    800033e4:	a9848493          	addi	s1,s1,-1384 # 8001fe78 <icache+0x18>
    800033e8:	0001e697          	auipc	a3,0x1e
    800033ec:	52068693          	addi	a3,a3,1312 # 80021908 <log>
    800033f0:	a039                	j	800033fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033f2:	02090b63          	beqz	s2,80003428 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033f6:	08848493          	addi	s1,s1,136
    800033fa:	02d48a63          	beq	s1,a3,8000342e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033fe:	449c                	lw	a5,8(s1)
    80003400:	fef059e3          	blez	a5,800033f2 <iget+0x38>
    80003404:	4098                	lw	a4,0(s1)
    80003406:	ff3716e3          	bne	a4,s3,800033f2 <iget+0x38>
    8000340a:	40d8                	lw	a4,4(s1)
    8000340c:	ff4713e3          	bne	a4,s4,800033f2 <iget+0x38>
      ip->ref++;
    80003410:	2785                	addiw	a5,a5,1
    80003412:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003414:	0001d517          	auipc	a0,0x1d
    80003418:	a4c50513          	addi	a0,a0,-1460 # 8001fe60 <icache>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	8a8080e7          	jalr	-1880(ra) # 80000cc4 <release>
      return ip;
    80003424:	8926                	mv	s2,s1
    80003426:	a03d                	j	80003454 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003428:	f7f9                	bnez	a5,800033f6 <iget+0x3c>
    8000342a:	8926                	mv	s2,s1
    8000342c:	b7e9                	j	800033f6 <iget+0x3c>
  if(empty == 0)
    8000342e:	02090c63          	beqz	s2,80003466 <iget+0xac>
  ip->dev = dev;
    80003432:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003436:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000343a:	4785                	li	a5,1
    8000343c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003440:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003444:	0001d517          	auipc	a0,0x1d
    80003448:	a1c50513          	addi	a0,a0,-1508 # 8001fe60 <icache>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	878080e7          	jalr	-1928(ra) # 80000cc4 <release>
}
    80003454:	854a                	mv	a0,s2
    80003456:	70a2                	ld	ra,40(sp)
    80003458:	7402                	ld	s0,32(sp)
    8000345a:	64e2                	ld	s1,24(sp)
    8000345c:	6942                	ld	s2,16(sp)
    8000345e:	69a2                	ld	s3,8(sp)
    80003460:	6a02                	ld	s4,0(sp)
    80003462:	6145                	addi	sp,sp,48
    80003464:	8082                	ret
    panic("iget: no inodes");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	08a50513          	addi	a0,a0,138 # 800084f0 <syscalls+0x130>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0da080e7          	jalr	218(ra) # 80000548 <panic>

0000000080003476 <fsinit>:
fsinit(int dev) {
    80003476:	7179                	addi	sp,sp,-48
    80003478:	f406                	sd	ra,40(sp)
    8000347a:	f022                	sd	s0,32(sp)
    8000347c:	ec26                	sd	s1,24(sp)
    8000347e:	e84a                	sd	s2,16(sp)
    80003480:	e44e                	sd	s3,8(sp)
    80003482:	1800                	addi	s0,sp,48
    80003484:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003486:	4585                	li	a1,1
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	a64080e7          	jalr	-1436(ra) # 80002eec <bread>
    80003490:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003492:	0001d997          	auipc	s3,0x1d
    80003496:	9ae98993          	addi	s3,s3,-1618 # 8001fe40 <sb>
    8000349a:	02000613          	li	a2,32
    8000349e:	05850593          	addi	a1,a0,88
    800034a2:	854e                	mv	a0,s3
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	8c8080e7          	jalr	-1848(ra) # 80000d6c <memmove>
  brelse(bp);
    800034ac:	8526                	mv	a0,s1
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	b6e080e7          	jalr	-1170(ra) # 8000301c <brelse>
  if(sb.magic != FSMAGIC)
    800034b6:	0009a703          	lw	a4,0(s3)
    800034ba:	102037b7          	lui	a5,0x10203
    800034be:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034c2:	02f71263          	bne	a4,a5,800034e6 <fsinit+0x70>
  initlog(dev, &sb);
    800034c6:	0001d597          	auipc	a1,0x1d
    800034ca:	97a58593          	addi	a1,a1,-1670 # 8001fe40 <sb>
    800034ce:	854a                	mv	a0,s2
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	b3c080e7          	jalr	-1220(ra) # 8000400c <initlog>
}
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6145                	addi	sp,sp,48
    800034e4:	8082                	ret
    panic("invalid file system");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	01a50513          	addi	a0,a0,26 # 80008500 <syscalls+0x140>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	05a080e7          	jalr	90(ra) # 80000548 <panic>

00000000800034f6 <iinit>:
{
    800034f6:	7179                	addi	sp,sp,-48
    800034f8:	f406                	sd	ra,40(sp)
    800034fa:	f022                	sd	s0,32(sp)
    800034fc:	ec26                	sd	s1,24(sp)
    800034fe:	e84a                	sd	s2,16(sp)
    80003500:	e44e                	sd	s3,8(sp)
    80003502:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003504:	00005597          	auipc	a1,0x5
    80003508:	01458593          	addi	a1,a1,20 # 80008518 <syscalls+0x158>
    8000350c:	0001d517          	auipc	a0,0x1d
    80003510:	95450513          	addi	a0,a0,-1708 # 8001fe60 <icache>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	66c080e7          	jalr	1644(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000351c:	0001d497          	auipc	s1,0x1d
    80003520:	96c48493          	addi	s1,s1,-1684 # 8001fe88 <icache+0x28>
    80003524:	0001e997          	auipc	s3,0x1e
    80003528:	3f498993          	addi	s3,s3,1012 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000352c:	00005917          	auipc	s2,0x5
    80003530:	ff490913          	addi	s2,s2,-12 # 80008520 <syscalls+0x160>
    80003534:	85ca                	mv	a1,s2
    80003536:	8526                	mv	a0,s1
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	e3a080e7          	jalr	-454(ra) # 80004372 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003540:	08848493          	addi	s1,s1,136
    80003544:	ff3498e3          	bne	s1,s3,80003534 <iinit+0x3e>
}
    80003548:	70a2                	ld	ra,40(sp)
    8000354a:	7402                	ld	s0,32(sp)
    8000354c:	64e2                	ld	s1,24(sp)
    8000354e:	6942                	ld	s2,16(sp)
    80003550:	69a2                	ld	s3,8(sp)
    80003552:	6145                	addi	sp,sp,48
    80003554:	8082                	ret

0000000080003556 <ialloc>:
{
    80003556:	715d                	addi	sp,sp,-80
    80003558:	e486                	sd	ra,72(sp)
    8000355a:	e0a2                	sd	s0,64(sp)
    8000355c:	fc26                	sd	s1,56(sp)
    8000355e:	f84a                	sd	s2,48(sp)
    80003560:	f44e                	sd	s3,40(sp)
    80003562:	f052                	sd	s4,32(sp)
    80003564:	ec56                	sd	s5,24(sp)
    80003566:	e85a                	sd	s6,16(sp)
    80003568:	e45e                	sd	s7,8(sp)
    8000356a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000356c:	0001d717          	auipc	a4,0x1d
    80003570:	8e072703          	lw	a4,-1824(a4) # 8001fe4c <sb+0xc>
    80003574:	4785                	li	a5,1
    80003576:	04e7fa63          	bgeu	a5,a4,800035ca <ialloc+0x74>
    8000357a:	8aaa                	mv	s5,a0
    8000357c:	8bae                	mv	s7,a1
    8000357e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003580:	0001da17          	auipc	s4,0x1d
    80003584:	8c0a0a13          	addi	s4,s4,-1856 # 8001fe40 <sb>
    80003588:	00048b1b          	sext.w	s6,s1
    8000358c:	0044d593          	srli	a1,s1,0x4
    80003590:	018a2783          	lw	a5,24(s4)
    80003594:	9dbd                	addw	a1,a1,a5
    80003596:	8556                	mv	a0,s5
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	954080e7          	jalr	-1708(ra) # 80002eec <bread>
    800035a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035a2:	05850993          	addi	s3,a0,88
    800035a6:	00f4f793          	andi	a5,s1,15
    800035aa:	079a                	slli	a5,a5,0x6
    800035ac:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ae:	00099783          	lh	a5,0(s3)
    800035b2:	c785                	beqz	a5,800035da <ialloc+0x84>
    brelse(bp);
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	a68080e7          	jalr	-1432(ra) # 8000301c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035bc:	0485                	addi	s1,s1,1
    800035be:	00ca2703          	lw	a4,12(s4)
    800035c2:	0004879b          	sext.w	a5,s1
    800035c6:	fce7e1e3          	bltu	a5,a4,80003588 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	f5e50513          	addi	a0,a0,-162 # 80008528 <syscalls+0x168>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f76080e7          	jalr	-138(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800035da:	04000613          	li	a2,64
    800035de:	4581                	li	a1,0
    800035e0:	854e                	mv	a0,s3
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	72a080e7          	jalr	1834(ra) # 80000d0c <memset>
      dip->type = type;
    800035ea:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035ee:	854a                	mv	a0,s2
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	c94080e7          	jalr	-876(ra) # 80004284 <log_write>
      brelse(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	a22080e7          	jalr	-1502(ra) # 8000301c <brelse>
      return iget(dev, inum);
    80003602:	85da                	mv	a1,s6
    80003604:	8556                	mv	a0,s5
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	db4080e7          	jalr	-588(ra) # 800033ba <iget>
}
    8000360e:	60a6                	ld	ra,72(sp)
    80003610:	6406                	ld	s0,64(sp)
    80003612:	74e2                	ld	s1,56(sp)
    80003614:	7942                	ld	s2,48(sp)
    80003616:	79a2                	ld	s3,40(sp)
    80003618:	7a02                	ld	s4,32(sp)
    8000361a:	6ae2                	ld	s5,24(sp)
    8000361c:	6b42                	ld	s6,16(sp)
    8000361e:	6ba2                	ld	s7,8(sp)
    80003620:	6161                	addi	sp,sp,80
    80003622:	8082                	ret

0000000080003624 <iupdate>:
{
    80003624:	1101                	addi	sp,sp,-32
    80003626:	ec06                	sd	ra,24(sp)
    80003628:	e822                	sd	s0,16(sp)
    8000362a:	e426                	sd	s1,8(sp)
    8000362c:	e04a                	sd	s2,0(sp)
    8000362e:	1000                	addi	s0,sp,32
    80003630:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003632:	415c                	lw	a5,4(a0)
    80003634:	0047d79b          	srliw	a5,a5,0x4
    80003638:	0001d597          	auipc	a1,0x1d
    8000363c:	8205a583          	lw	a1,-2016(a1) # 8001fe58 <sb+0x18>
    80003640:	9dbd                	addw	a1,a1,a5
    80003642:	4108                	lw	a0,0(a0)
    80003644:	00000097          	auipc	ra,0x0
    80003648:	8a8080e7          	jalr	-1880(ra) # 80002eec <bread>
    8000364c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000364e:	05850793          	addi	a5,a0,88
    80003652:	40c8                	lw	a0,4(s1)
    80003654:	893d                	andi	a0,a0,15
    80003656:	051a                	slli	a0,a0,0x6
    80003658:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000365a:	04449703          	lh	a4,68(s1)
    8000365e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003662:	04649703          	lh	a4,70(s1)
    80003666:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000366a:	04849703          	lh	a4,72(s1)
    8000366e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003672:	04a49703          	lh	a4,74(s1)
    80003676:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000367a:	44f8                	lw	a4,76(s1)
    8000367c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000367e:	03400613          	li	a2,52
    80003682:	05048593          	addi	a1,s1,80
    80003686:	0531                	addi	a0,a0,12
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	6e4080e7          	jalr	1764(ra) # 80000d6c <memmove>
  log_write(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00001097          	auipc	ra,0x1
    80003696:	bf2080e7          	jalr	-1038(ra) # 80004284 <log_write>
  brelse(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	980080e7          	jalr	-1664(ra) # 8000301c <brelse>
}
    800036a4:	60e2                	ld	ra,24(sp)
    800036a6:	6442                	ld	s0,16(sp)
    800036a8:	64a2                	ld	s1,8(sp)
    800036aa:	6902                	ld	s2,0(sp)
    800036ac:	6105                	addi	sp,sp,32
    800036ae:	8082                	ret

00000000800036b0 <idup>:
{
    800036b0:	1101                	addi	sp,sp,-32
    800036b2:	ec06                	sd	ra,24(sp)
    800036b4:	e822                	sd	s0,16(sp)
    800036b6:	e426                	sd	s1,8(sp)
    800036b8:	1000                	addi	s0,sp,32
    800036ba:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036bc:	0001c517          	auipc	a0,0x1c
    800036c0:	7a450513          	addi	a0,a0,1956 # 8001fe60 <icache>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	54c080e7          	jalr	1356(ra) # 80000c10 <acquire>
  ip->ref++;
    800036cc:	449c                	lw	a5,8(s1)
    800036ce:	2785                	addiw	a5,a5,1
    800036d0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036d2:	0001c517          	auipc	a0,0x1c
    800036d6:	78e50513          	addi	a0,a0,1934 # 8001fe60 <icache>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	5ea080e7          	jalr	1514(ra) # 80000cc4 <release>
}
    800036e2:	8526                	mv	a0,s1
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret

00000000800036ee <ilock>:
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	e04a                	sd	s2,0(sp)
    800036f8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036fa:	c115                	beqz	a0,8000371e <ilock+0x30>
    800036fc:	84aa                	mv	s1,a0
    800036fe:	451c                	lw	a5,8(a0)
    80003700:	00f05f63          	blez	a5,8000371e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003704:	0541                	addi	a0,a0,16
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	ca6080e7          	jalr	-858(ra) # 800043ac <acquiresleep>
  if(ip->valid == 0){
    8000370e:	40bc                	lw	a5,64(s1)
    80003710:	cf99                	beqz	a5,8000372e <ilock+0x40>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6902                	ld	s2,0(sp)
    8000371a:	6105                	addi	sp,sp,32
    8000371c:	8082                	ret
    panic("ilock");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	e2250513          	addi	a0,a0,-478 # 80008540 <syscalls+0x180>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000372e:	40dc                	lw	a5,4(s1)
    80003730:	0047d79b          	srliw	a5,a5,0x4
    80003734:	0001c597          	auipc	a1,0x1c
    80003738:	7245a583          	lw	a1,1828(a1) # 8001fe58 <sb+0x18>
    8000373c:	9dbd                	addw	a1,a1,a5
    8000373e:	4088                	lw	a0,0(s1)
    80003740:	fffff097          	auipc	ra,0xfffff
    80003744:	7ac080e7          	jalr	1964(ra) # 80002eec <bread>
    80003748:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000374a:	05850593          	addi	a1,a0,88
    8000374e:	40dc                	lw	a5,4(s1)
    80003750:	8bbd                	andi	a5,a5,15
    80003752:	079a                	slli	a5,a5,0x6
    80003754:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003756:	00059783          	lh	a5,0(a1)
    8000375a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000375e:	00259783          	lh	a5,2(a1)
    80003762:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003766:	00459783          	lh	a5,4(a1)
    8000376a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000376e:	00659783          	lh	a5,6(a1)
    80003772:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003776:	459c                	lw	a5,8(a1)
    80003778:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000377a:	03400613          	li	a2,52
    8000377e:	05b1                	addi	a1,a1,12
    80003780:	05048513          	addi	a0,s1,80
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	5e8080e7          	jalr	1512(ra) # 80000d6c <memmove>
    brelse(bp);
    8000378c:	854a                	mv	a0,s2
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	88e080e7          	jalr	-1906(ra) # 8000301c <brelse>
    ip->valid = 1;
    80003796:	4785                	li	a5,1
    80003798:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000379a:	04449783          	lh	a5,68(s1)
    8000379e:	fbb5                	bnez	a5,80003712 <ilock+0x24>
      panic("ilock: no type");
    800037a0:	00005517          	auipc	a0,0x5
    800037a4:	da850513          	addi	a0,a0,-600 # 80008548 <syscalls+0x188>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	da0080e7          	jalr	-608(ra) # 80000548 <panic>

00000000800037b0 <iunlock>:
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	e04a                	sd	s2,0(sp)
    800037ba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037bc:	c905                	beqz	a0,800037ec <iunlock+0x3c>
    800037be:	84aa                	mv	s1,a0
    800037c0:	01050913          	addi	s2,a0,16
    800037c4:	854a                	mv	a0,s2
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	c80080e7          	jalr	-896(ra) # 80004446 <holdingsleep>
    800037ce:	cd19                	beqz	a0,800037ec <iunlock+0x3c>
    800037d0:	449c                	lw	a5,8(s1)
    800037d2:	00f05d63          	blez	a5,800037ec <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	c2a080e7          	jalr	-982(ra) # 80004402 <releasesleep>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6902                	ld	s2,0(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret
    panic("iunlock");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	d6c50513          	addi	a0,a0,-660 # 80008558 <syscalls+0x198>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d54080e7          	jalr	-684(ra) # 80000548 <panic>

00000000800037fc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037fc:	7179                	addi	sp,sp,-48
    800037fe:	f406                	sd	ra,40(sp)
    80003800:	f022                	sd	s0,32(sp)
    80003802:	ec26                	sd	s1,24(sp)
    80003804:	e84a                	sd	s2,16(sp)
    80003806:	e44e                	sd	s3,8(sp)
    80003808:	e052                	sd	s4,0(sp)
    8000380a:	1800                	addi	s0,sp,48
    8000380c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000380e:	05050493          	addi	s1,a0,80
    80003812:	08050913          	addi	s2,a0,128
    80003816:	a021                	j	8000381e <itrunc+0x22>
    80003818:	0491                	addi	s1,s1,4
    8000381a:	01248d63          	beq	s1,s2,80003834 <itrunc+0x38>
    if(ip->addrs[i]){
    8000381e:	408c                	lw	a1,0(s1)
    80003820:	dde5                	beqz	a1,80003818 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003822:	0009a503          	lw	a0,0(s3)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	90c080e7          	jalr	-1780(ra) # 80003132 <bfree>
      ip->addrs[i] = 0;
    8000382e:	0004a023          	sw	zero,0(s1)
    80003832:	b7dd                	j	80003818 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003834:	0809a583          	lw	a1,128(s3)
    80003838:	e185                	bnez	a1,80003858 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000383a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000383e:	854e                	mv	a0,s3
    80003840:	00000097          	auipc	ra,0x0
    80003844:	de4080e7          	jalr	-540(ra) # 80003624 <iupdate>
}
    80003848:	70a2                	ld	ra,40(sp)
    8000384a:	7402                	ld	s0,32(sp)
    8000384c:	64e2                	ld	s1,24(sp)
    8000384e:	6942                	ld	s2,16(sp)
    80003850:	69a2                	ld	s3,8(sp)
    80003852:	6a02                	ld	s4,0(sp)
    80003854:	6145                	addi	sp,sp,48
    80003856:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003858:	0009a503          	lw	a0,0(s3)
    8000385c:	fffff097          	auipc	ra,0xfffff
    80003860:	690080e7          	jalr	1680(ra) # 80002eec <bread>
    80003864:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003866:	05850493          	addi	s1,a0,88
    8000386a:	45850913          	addi	s2,a0,1112
    8000386e:	a811                	j	80003882 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003870:	0009a503          	lw	a0,0(s3)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	8be080e7          	jalr	-1858(ra) # 80003132 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000387c:	0491                	addi	s1,s1,4
    8000387e:	01248563          	beq	s1,s2,80003888 <itrunc+0x8c>
      if(a[j])
    80003882:	408c                	lw	a1,0(s1)
    80003884:	dde5                	beqz	a1,8000387c <itrunc+0x80>
    80003886:	b7ed                	j	80003870 <itrunc+0x74>
    brelse(bp);
    80003888:	8552                	mv	a0,s4
    8000388a:	fffff097          	auipc	ra,0xfffff
    8000388e:	792080e7          	jalr	1938(ra) # 8000301c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003892:	0809a583          	lw	a1,128(s3)
    80003896:	0009a503          	lw	a0,0(s3)
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	898080e7          	jalr	-1896(ra) # 80003132 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038a2:	0809a023          	sw	zero,128(s3)
    800038a6:	bf51                	j	8000383a <itrunc+0x3e>

00000000800038a8 <iput>:
{
    800038a8:	1101                	addi	sp,sp,-32
    800038aa:	ec06                	sd	ra,24(sp)
    800038ac:	e822                	sd	s0,16(sp)
    800038ae:	e426                	sd	s1,8(sp)
    800038b0:	e04a                	sd	s2,0(sp)
    800038b2:	1000                	addi	s0,sp,32
    800038b4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038b6:	0001c517          	auipc	a0,0x1c
    800038ba:	5aa50513          	addi	a0,a0,1450 # 8001fe60 <icache>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	352080e7          	jalr	850(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038c6:	4498                	lw	a4,8(s1)
    800038c8:	4785                	li	a5,1
    800038ca:	02f70363          	beq	a4,a5,800038f0 <iput+0x48>
  ip->ref--;
    800038ce:	449c                	lw	a5,8(s1)
    800038d0:	37fd                	addiw	a5,a5,-1
    800038d2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038d4:	0001c517          	auipc	a0,0x1c
    800038d8:	58c50513          	addi	a0,a0,1420 # 8001fe60 <icache>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	3e8080e7          	jalr	1000(ra) # 80000cc4 <release>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6902                	ld	s2,0(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	dff1                	beqz	a5,800038ce <iput+0x26>
    800038f4:	04a49783          	lh	a5,74(s1)
    800038f8:	fbf9                	bnez	a5,800038ce <iput+0x26>
    acquiresleep(&ip->lock);
    800038fa:	01048913          	addi	s2,s1,16
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	aac080e7          	jalr	-1364(ra) # 800043ac <acquiresleep>
    release(&icache.lock);
    80003908:	0001c517          	auipc	a0,0x1c
    8000390c:	55850513          	addi	a0,a0,1368 # 8001fe60 <icache>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	3b4080e7          	jalr	948(ra) # 80000cc4 <release>
    itrunc(ip);
    80003918:	8526                	mv	a0,s1
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	ee2080e7          	jalr	-286(ra) # 800037fc <itrunc>
    ip->type = 0;
    80003922:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003926:	8526                	mv	a0,s1
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	cfc080e7          	jalr	-772(ra) # 80003624 <iupdate>
    ip->valid = 0;
    80003930:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003934:	854a                	mv	a0,s2
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	acc080e7          	jalr	-1332(ra) # 80004402 <releasesleep>
    acquire(&icache.lock);
    8000393e:	0001c517          	auipc	a0,0x1c
    80003942:	52250513          	addi	a0,a0,1314 # 8001fe60 <icache>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	2ca080e7          	jalr	714(ra) # 80000c10 <acquire>
    8000394e:	b741                	j	800038ce <iput+0x26>

0000000080003950 <iunlockput>:
{
    80003950:	1101                	addi	sp,sp,-32
    80003952:	ec06                	sd	ra,24(sp)
    80003954:	e822                	sd	s0,16(sp)
    80003956:	e426                	sd	s1,8(sp)
    80003958:	1000                	addi	s0,sp,32
    8000395a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	e54080e7          	jalr	-428(ra) # 800037b0 <iunlock>
  iput(ip);
    80003964:	8526                	mv	a0,s1
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	f42080e7          	jalr	-190(ra) # 800038a8 <iput>
}
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret

0000000080003978 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003978:	1141                	addi	sp,sp,-16
    8000397a:	e422                	sd	s0,8(sp)
    8000397c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000397e:	411c                	lw	a5,0(a0)
    80003980:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003982:	415c                	lw	a5,4(a0)
    80003984:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003986:	04451783          	lh	a5,68(a0)
    8000398a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000398e:	04a51783          	lh	a5,74(a0)
    80003992:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003996:	04c56783          	lwu	a5,76(a0)
    8000399a:	e99c                	sd	a5,16(a1)
}
    8000399c:	6422                	ld	s0,8(sp)
    8000399e:	0141                	addi	sp,sp,16
    800039a0:	8082                	ret

00000000800039a2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039a2:	457c                	lw	a5,76(a0)
    800039a4:	0ed7e963          	bltu	a5,a3,80003a96 <readi+0xf4>
{
    800039a8:	7159                	addi	sp,sp,-112
    800039aa:	f486                	sd	ra,104(sp)
    800039ac:	f0a2                	sd	s0,96(sp)
    800039ae:	eca6                	sd	s1,88(sp)
    800039b0:	e8ca                	sd	s2,80(sp)
    800039b2:	e4ce                	sd	s3,72(sp)
    800039b4:	e0d2                	sd	s4,64(sp)
    800039b6:	fc56                	sd	s5,56(sp)
    800039b8:	f85a                	sd	s6,48(sp)
    800039ba:	f45e                	sd	s7,40(sp)
    800039bc:	f062                	sd	s8,32(sp)
    800039be:	ec66                	sd	s9,24(sp)
    800039c0:	e86a                	sd	s10,16(sp)
    800039c2:	e46e                	sd	s11,8(sp)
    800039c4:	1880                	addi	s0,sp,112
    800039c6:	8baa                	mv	s7,a0
    800039c8:	8c2e                	mv	s8,a1
    800039ca:	8ab2                	mv	s5,a2
    800039cc:	84b6                	mv	s1,a3
    800039ce:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039d0:	9f35                	addw	a4,a4,a3
    return 0;
    800039d2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039d4:	0ad76063          	bltu	a4,a3,80003a74 <readi+0xd2>
  if(off + n > ip->size)
    800039d8:	00e7f463          	bgeu	a5,a4,800039e0 <readi+0x3e>
    n = ip->size - off;
    800039dc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039e0:	0a0b0963          	beqz	s6,80003a92 <readi+0xf0>
    800039e4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039ea:	5cfd                	li	s9,-1
    800039ec:	a82d                	j	80003a26 <readi+0x84>
    800039ee:	020a1d93          	slli	s11,s4,0x20
    800039f2:	020ddd93          	srli	s11,s11,0x20
    800039f6:	05890613          	addi	a2,s2,88
    800039fa:	86ee                	mv	a3,s11
    800039fc:	963a                	add	a2,a2,a4
    800039fe:	85d6                	mv	a1,s5
    80003a00:	8562                	mv	a0,s8
    80003a02:	fffff097          	auipc	ra,0xfffff
    80003a06:	aa8080e7          	jalr	-1368(ra) # 800024aa <either_copyout>
    80003a0a:	05950d63          	beq	a0,s9,80003a64 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	60c080e7          	jalr	1548(ra) # 8000301c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a18:	013a09bb          	addw	s3,s4,s3
    80003a1c:	009a04bb          	addw	s1,s4,s1
    80003a20:	9aee                	add	s5,s5,s11
    80003a22:	0569f763          	bgeu	s3,s6,80003a70 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a26:	000ba903          	lw	s2,0(s7)
    80003a2a:	00a4d59b          	srliw	a1,s1,0xa
    80003a2e:	855e                	mv	a0,s7
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	8b0080e7          	jalr	-1872(ra) # 800032e0 <bmap>
    80003a38:	0005059b          	sext.w	a1,a0
    80003a3c:	854a                	mv	a0,s2
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	4ae080e7          	jalr	1198(ra) # 80002eec <bread>
    80003a46:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a48:	3ff4f713          	andi	a4,s1,1023
    80003a4c:	40ed07bb          	subw	a5,s10,a4
    80003a50:	413b06bb          	subw	a3,s6,s3
    80003a54:	8a3e                	mv	s4,a5
    80003a56:	2781                	sext.w	a5,a5
    80003a58:	0006861b          	sext.w	a2,a3
    80003a5c:	f8f679e3          	bgeu	a2,a5,800039ee <readi+0x4c>
    80003a60:	8a36                	mv	s4,a3
    80003a62:	b771                	j	800039ee <readi+0x4c>
      brelse(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	5b6080e7          	jalr	1462(ra) # 8000301c <brelse>
      tot = -1;
    80003a6e:	59fd                	li	s3,-1
  }
  return tot;
    80003a70:	0009851b          	sext.w	a0,s3
}
    80003a74:	70a6                	ld	ra,104(sp)
    80003a76:	7406                	ld	s0,96(sp)
    80003a78:	64e6                	ld	s1,88(sp)
    80003a7a:	6946                	ld	s2,80(sp)
    80003a7c:	69a6                	ld	s3,72(sp)
    80003a7e:	6a06                	ld	s4,64(sp)
    80003a80:	7ae2                	ld	s5,56(sp)
    80003a82:	7b42                	ld	s6,48(sp)
    80003a84:	7ba2                	ld	s7,40(sp)
    80003a86:	7c02                	ld	s8,32(sp)
    80003a88:	6ce2                	ld	s9,24(sp)
    80003a8a:	6d42                	ld	s10,16(sp)
    80003a8c:	6da2                	ld	s11,8(sp)
    80003a8e:	6165                	addi	sp,sp,112
    80003a90:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a92:	89da                	mv	s3,s6
    80003a94:	bff1                	j	80003a70 <readi+0xce>
    return 0;
    80003a96:	4501                	li	a0,0
}
    80003a98:	8082                	ret

0000000080003a9a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a9a:	457c                	lw	a5,76(a0)
    80003a9c:	10d7e763          	bltu	a5,a3,80003baa <writei+0x110>
{
    80003aa0:	7159                	addi	sp,sp,-112
    80003aa2:	f486                	sd	ra,104(sp)
    80003aa4:	f0a2                	sd	s0,96(sp)
    80003aa6:	eca6                	sd	s1,88(sp)
    80003aa8:	e8ca                	sd	s2,80(sp)
    80003aaa:	e4ce                	sd	s3,72(sp)
    80003aac:	e0d2                	sd	s4,64(sp)
    80003aae:	fc56                	sd	s5,56(sp)
    80003ab0:	f85a                	sd	s6,48(sp)
    80003ab2:	f45e                	sd	s7,40(sp)
    80003ab4:	f062                	sd	s8,32(sp)
    80003ab6:	ec66                	sd	s9,24(sp)
    80003ab8:	e86a                	sd	s10,16(sp)
    80003aba:	e46e                	sd	s11,8(sp)
    80003abc:	1880                	addi	s0,sp,112
    80003abe:	8baa                	mv	s7,a0
    80003ac0:	8c2e                	mv	s8,a1
    80003ac2:	8ab2                	mv	s5,a2
    80003ac4:	8936                	mv	s2,a3
    80003ac6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac8:	00e687bb          	addw	a5,a3,a4
    80003acc:	0ed7e163          	bltu	a5,a3,80003bae <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ad0:	00043737          	lui	a4,0x43
    80003ad4:	0cf76f63          	bltu	a4,a5,80003bb2 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad8:	0a0b0863          	beqz	s6,80003b88 <writei+0xee>
    80003adc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ade:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ae2:	5cfd                	li	s9,-1
    80003ae4:	a091                	j	80003b28 <writei+0x8e>
    80003ae6:	02099d93          	slli	s11,s3,0x20
    80003aea:	020ddd93          	srli	s11,s11,0x20
    80003aee:	05848513          	addi	a0,s1,88
    80003af2:	86ee                	mv	a3,s11
    80003af4:	8656                	mv	a2,s5
    80003af6:	85e2                	mv	a1,s8
    80003af8:	953a                	add	a0,a0,a4
    80003afa:	fffff097          	auipc	ra,0xfffff
    80003afe:	a06080e7          	jalr	-1530(ra) # 80002500 <either_copyin>
    80003b02:	07950263          	beq	a0,s9,80003b66 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b06:	8526                	mv	a0,s1
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	77c080e7          	jalr	1916(ra) # 80004284 <log_write>
    brelse(bp);
    80003b10:	8526                	mv	a0,s1
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	50a080e7          	jalr	1290(ra) # 8000301c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b1a:	01498a3b          	addw	s4,s3,s4
    80003b1e:	0129893b          	addw	s2,s3,s2
    80003b22:	9aee                	add	s5,s5,s11
    80003b24:	056a7763          	bgeu	s4,s6,80003b72 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b28:	000ba483          	lw	s1,0(s7)
    80003b2c:	00a9559b          	srliw	a1,s2,0xa
    80003b30:	855e                	mv	a0,s7
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	7ae080e7          	jalr	1966(ra) # 800032e0 <bmap>
    80003b3a:	0005059b          	sext.w	a1,a0
    80003b3e:	8526                	mv	a0,s1
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	3ac080e7          	jalr	940(ra) # 80002eec <bread>
    80003b48:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4a:	3ff97713          	andi	a4,s2,1023
    80003b4e:	40ed07bb          	subw	a5,s10,a4
    80003b52:	414b06bb          	subw	a3,s6,s4
    80003b56:	89be                	mv	s3,a5
    80003b58:	2781                	sext.w	a5,a5
    80003b5a:	0006861b          	sext.w	a2,a3
    80003b5e:	f8f674e3          	bgeu	a2,a5,80003ae6 <writei+0x4c>
    80003b62:	89b6                	mv	s3,a3
    80003b64:	b749                	j	80003ae6 <writei+0x4c>
      brelse(bp);
    80003b66:	8526                	mv	a0,s1
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	4b4080e7          	jalr	1204(ra) # 8000301c <brelse>
      n = -1;
    80003b70:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003b72:	04cba783          	lw	a5,76(s7)
    80003b76:	0127f463          	bgeu	a5,s2,80003b7e <writei+0xe4>
      ip->size = off;
    80003b7a:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b7e:	855e                	mv	a0,s7
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	aa4080e7          	jalr	-1372(ra) # 80003624 <iupdate>
  }

  return n;
    80003b88:	000b051b          	sext.w	a0,s6
}
    80003b8c:	70a6                	ld	ra,104(sp)
    80003b8e:	7406                	ld	s0,96(sp)
    80003b90:	64e6                	ld	s1,88(sp)
    80003b92:	6946                	ld	s2,80(sp)
    80003b94:	69a6                	ld	s3,72(sp)
    80003b96:	6a06                	ld	s4,64(sp)
    80003b98:	7ae2                	ld	s5,56(sp)
    80003b9a:	7b42                	ld	s6,48(sp)
    80003b9c:	7ba2                	ld	s7,40(sp)
    80003b9e:	7c02                	ld	s8,32(sp)
    80003ba0:	6ce2                	ld	s9,24(sp)
    80003ba2:	6d42                	ld	s10,16(sp)
    80003ba4:	6da2                	ld	s11,8(sp)
    80003ba6:	6165                	addi	sp,sp,112
    80003ba8:	8082                	ret
    return -1;
    80003baa:	557d                	li	a0,-1
}
    80003bac:	8082                	ret
    return -1;
    80003bae:	557d                	li	a0,-1
    80003bb0:	bff1                	j	80003b8c <writei+0xf2>
    return -1;
    80003bb2:	557d                	li	a0,-1
    80003bb4:	bfe1                	j	80003b8c <writei+0xf2>

0000000080003bb6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bb6:	1141                	addi	sp,sp,-16
    80003bb8:	e406                	sd	ra,8(sp)
    80003bba:	e022                	sd	s0,0(sp)
    80003bbc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bbe:	4639                	li	a2,14
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	228080e7          	jalr	552(ra) # 80000de8 <strncmp>
}
    80003bc8:	60a2                	ld	ra,8(sp)
    80003bca:	6402                	ld	s0,0(sp)
    80003bcc:	0141                	addi	sp,sp,16
    80003bce:	8082                	ret

0000000080003bd0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bd0:	7139                	addi	sp,sp,-64
    80003bd2:	fc06                	sd	ra,56(sp)
    80003bd4:	f822                	sd	s0,48(sp)
    80003bd6:	f426                	sd	s1,40(sp)
    80003bd8:	f04a                	sd	s2,32(sp)
    80003bda:	ec4e                	sd	s3,24(sp)
    80003bdc:	e852                	sd	s4,16(sp)
    80003bde:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003be0:	04451703          	lh	a4,68(a0)
    80003be4:	4785                	li	a5,1
    80003be6:	00f71a63          	bne	a4,a5,80003bfa <dirlookup+0x2a>
    80003bea:	892a                	mv	s2,a0
    80003bec:	89ae                	mv	s3,a1
    80003bee:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf0:	457c                	lw	a5,76(a0)
    80003bf2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bf4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf6:	e79d                	bnez	a5,80003c24 <dirlookup+0x54>
    80003bf8:	a8a5                	j	80003c70 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bfa:	00005517          	auipc	a0,0x5
    80003bfe:	96650513          	addi	a0,a0,-1690 # 80008560 <syscalls+0x1a0>
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	946080e7          	jalr	-1722(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	96e50513          	addi	a0,a0,-1682 # 80008578 <syscalls+0x1b8>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	936080e7          	jalr	-1738(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1a:	24c1                	addiw	s1,s1,16
    80003c1c:	04c92783          	lw	a5,76(s2)
    80003c20:	04f4f763          	bgeu	s1,a5,80003c6e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c24:	4741                	li	a4,16
    80003c26:	86a6                	mv	a3,s1
    80003c28:	fc040613          	addi	a2,s0,-64
    80003c2c:	4581                	li	a1,0
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	d72080e7          	jalr	-654(ra) # 800039a2 <readi>
    80003c38:	47c1                	li	a5,16
    80003c3a:	fcf518e3          	bne	a0,a5,80003c0a <dirlookup+0x3a>
    if(de.inum == 0)
    80003c3e:	fc045783          	lhu	a5,-64(s0)
    80003c42:	dfe1                	beqz	a5,80003c1a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c44:	fc240593          	addi	a1,s0,-62
    80003c48:	854e                	mv	a0,s3
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	f6c080e7          	jalr	-148(ra) # 80003bb6 <namecmp>
    80003c52:	f561                	bnez	a0,80003c1a <dirlookup+0x4a>
      if(poff)
    80003c54:	000a0463          	beqz	s4,80003c5c <dirlookup+0x8c>
        *poff = off;
    80003c58:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c5c:	fc045583          	lhu	a1,-64(s0)
    80003c60:	00092503          	lw	a0,0(s2)
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	756080e7          	jalr	1878(ra) # 800033ba <iget>
    80003c6c:	a011                	j	80003c70 <dirlookup+0xa0>
  return 0;
    80003c6e:	4501                	li	a0,0
}
    80003c70:	70e2                	ld	ra,56(sp)
    80003c72:	7442                	ld	s0,48(sp)
    80003c74:	74a2                	ld	s1,40(sp)
    80003c76:	7902                	ld	s2,32(sp)
    80003c78:	69e2                	ld	s3,24(sp)
    80003c7a:	6a42                	ld	s4,16(sp)
    80003c7c:	6121                	addi	sp,sp,64
    80003c7e:	8082                	ret

0000000080003c80 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c80:	711d                	addi	sp,sp,-96
    80003c82:	ec86                	sd	ra,88(sp)
    80003c84:	e8a2                	sd	s0,80(sp)
    80003c86:	e4a6                	sd	s1,72(sp)
    80003c88:	e0ca                	sd	s2,64(sp)
    80003c8a:	fc4e                	sd	s3,56(sp)
    80003c8c:	f852                	sd	s4,48(sp)
    80003c8e:	f456                	sd	s5,40(sp)
    80003c90:	f05a                	sd	s6,32(sp)
    80003c92:	ec5e                	sd	s7,24(sp)
    80003c94:	e862                	sd	s8,16(sp)
    80003c96:	e466                	sd	s9,8(sp)
    80003c98:	1080                	addi	s0,sp,96
    80003c9a:	84aa                	mv	s1,a0
    80003c9c:	8b2e                	mv	s6,a1
    80003c9e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ca0:	00054703          	lbu	a4,0(a0)
    80003ca4:	02f00793          	li	a5,47
    80003ca8:	02f70363          	beq	a4,a5,80003cce <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cac:	ffffe097          	auipc	ra,0xffffe
    80003cb0:	d8c080e7          	jalr	-628(ra) # 80001a38 <myproc>
    80003cb4:	15053503          	ld	a0,336(a0)
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	9f8080e7          	jalr	-1544(ra) # 800036b0 <idup>
    80003cc0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cc2:	02f00913          	li	s2,47
  len = path - s;
    80003cc6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cc8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cca:	4c05                	li	s8,1
    80003ccc:	a865                	j	80003d84 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cce:	4585                	li	a1,1
    80003cd0:	4505                	li	a0,1
    80003cd2:	fffff097          	auipc	ra,0xfffff
    80003cd6:	6e8080e7          	jalr	1768(ra) # 800033ba <iget>
    80003cda:	89aa                	mv	s3,a0
    80003cdc:	b7dd                	j	80003cc2 <namex+0x42>
      iunlockput(ip);
    80003cde:	854e                	mv	a0,s3
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	c70080e7          	jalr	-912(ra) # 80003950 <iunlockput>
      return 0;
    80003ce8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cea:	854e                	mv	a0,s3
    80003cec:	60e6                	ld	ra,88(sp)
    80003cee:	6446                	ld	s0,80(sp)
    80003cf0:	64a6                	ld	s1,72(sp)
    80003cf2:	6906                	ld	s2,64(sp)
    80003cf4:	79e2                	ld	s3,56(sp)
    80003cf6:	7a42                	ld	s4,48(sp)
    80003cf8:	7aa2                	ld	s5,40(sp)
    80003cfa:	7b02                	ld	s6,32(sp)
    80003cfc:	6be2                	ld	s7,24(sp)
    80003cfe:	6c42                	ld	s8,16(sp)
    80003d00:	6ca2                	ld	s9,8(sp)
    80003d02:	6125                	addi	sp,sp,96
    80003d04:	8082                	ret
      iunlock(ip);
    80003d06:	854e                	mv	a0,s3
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	aa8080e7          	jalr	-1368(ra) # 800037b0 <iunlock>
      return ip;
    80003d10:	bfe9                	j	80003cea <namex+0x6a>
      iunlockput(ip);
    80003d12:	854e                	mv	a0,s3
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	c3c080e7          	jalr	-964(ra) # 80003950 <iunlockput>
      return 0;
    80003d1c:	89d2                	mv	s3,s4
    80003d1e:	b7f1                	j	80003cea <namex+0x6a>
  len = path - s;
    80003d20:	40b48633          	sub	a2,s1,a1
    80003d24:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d28:	094cd463          	bge	s9,s4,80003db0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d2c:	4639                	li	a2,14
    80003d2e:	8556                	mv	a0,s5
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	03c080e7          	jalr	60(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d38:	0004c783          	lbu	a5,0(s1)
    80003d3c:	01279763          	bne	a5,s2,80003d4a <namex+0xca>
    path++;
    80003d40:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d42:	0004c783          	lbu	a5,0(s1)
    80003d46:	ff278de3          	beq	a5,s2,80003d40 <namex+0xc0>
    ilock(ip);
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	9a2080e7          	jalr	-1630(ra) # 800036ee <ilock>
    if(ip->type != T_DIR){
    80003d54:	04499783          	lh	a5,68(s3)
    80003d58:	f98793e3          	bne	a5,s8,80003cde <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d5c:	000b0563          	beqz	s6,80003d66 <namex+0xe6>
    80003d60:	0004c783          	lbu	a5,0(s1)
    80003d64:	d3cd                	beqz	a5,80003d06 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d66:	865e                	mv	a2,s7
    80003d68:	85d6                	mv	a1,s5
    80003d6a:	854e                	mv	a0,s3
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	e64080e7          	jalr	-412(ra) # 80003bd0 <dirlookup>
    80003d74:	8a2a                	mv	s4,a0
    80003d76:	dd51                	beqz	a0,80003d12 <namex+0x92>
    iunlockput(ip);
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	bd6080e7          	jalr	-1066(ra) # 80003950 <iunlockput>
    ip = next;
    80003d82:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	05279763          	bne	a5,s2,80003dd6 <namex+0x156>
    path++;
    80003d8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	ff278de3          	beq	a5,s2,80003d8c <namex+0x10c>
  if(*path == 0)
    80003d96:	c79d                	beqz	a5,80003dc4 <namex+0x144>
    path++;
    80003d98:	85a6                	mv	a1,s1
  len = path - s;
    80003d9a:	8a5e                	mv	s4,s7
    80003d9c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d9e:	01278963          	beq	a5,s2,80003db0 <namex+0x130>
    80003da2:	dfbd                	beqz	a5,80003d20 <namex+0xa0>
    path++;
    80003da4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003da6:	0004c783          	lbu	a5,0(s1)
    80003daa:	ff279ce3          	bne	a5,s2,80003da2 <namex+0x122>
    80003dae:	bf8d                	j	80003d20 <namex+0xa0>
    memmove(name, s, len);
    80003db0:	2601                	sext.w	a2,a2
    80003db2:	8556                	mv	a0,s5
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	fb8080e7          	jalr	-72(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003dbc:	9a56                	add	s4,s4,s5
    80003dbe:	000a0023          	sb	zero,0(s4)
    80003dc2:	bf9d                	j	80003d38 <namex+0xb8>
  if(nameiparent){
    80003dc4:	f20b03e3          	beqz	s6,80003cea <namex+0x6a>
    iput(ip);
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	ade080e7          	jalr	-1314(ra) # 800038a8 <iput>
    return 0;
    80003dd2:	4981                	li	s3,0
    80003dd4:	bf19                	j	80003cea <namex+0x6a>
  if(*path == 0)
    80003dd6:	d7fd                	beqz	a5,80003dc4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dd8:	0004c783          	lbu	a5,0(s1)
    80003ddc:	85a6                	mv	a1,s1
    80003dde:	b7d1                	j	80003da2 <namex+0x122>

0000000080003de0 <dirlink>:
{
    80003de0:	7139                	addi	sp,sp,-64
    80003de2:	fc06                	sd	ra,56(sp)
    80003de4:	f822                	sd	s0,48(sp)
    80003de6:	f426                	sd	s1,40(sp)
    80003de8:	f04a                	sd	s2,32(sp)
    80003dea:	ec4e                	sd	s3,24(sp)
    80003dec:	e852                	sd	s4,16(sp)
    80003dee:	0080                	addi	s0,sp,64
    80003df0:	892a                	mv	s2,a0
    80003df2:	8a2e                	mv	s4,a1
    80003df4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003df6:	4601                	li	a2,0
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	dd8080e7          	jalr	-552(ra) # 80003bd0 <dirlookup>
    80003e00:	e93d                	bnez	a0,80003e76 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e02:	04c92483          	lw	s1,76(s2)
    80003e06:	c49d                	beqz	s1,80003e34 <dirlink+0x54>
    80003e08:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0a:	4741                	li	a4,16
    80003e0c:	86a6                	mv	a3,s1
    80003e0e:	fc040613          	addi	a2,s0,-64
    80003e12:	4581                	li	a1,0
    80003e14:	854a                	mv	a0,s2
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	b8c080e7          	jalr	-1140(ra) # 800039a2 <readi>
    80003e1e:	47c1                	li	a5,16
    80003e20:	06f51163          	bne	a0,a5,80003e82 <dirlink+0xa2>
    if(de.inum == 0)
    80003e24:	fc045783          	lhu	a5,-64(s0)
    80003e28:	c791                	beqz	a5,80003e34 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2a:	24c1                	addiw	s1,s1,16
    80003e2c:	04c92783          	lw	a5,76(s2)
    80003e30:	fcf4ede3          	bltu	s1,a5,80003e0a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e34:	4639                	li	a2,14
    80003e36:	85d2                	mv	a1,s4
    80003e38:	fc240513          	addi	a0,s0,-62
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	fe8080e7          	jalr	-24(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003e44:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e48:	4741                	li	a4,16
    80003e4a:	86a6                	mv	a3,s1
    80003e4c:	fc040613          	addi	a2,s0,-64
    80003e50:	4581                	li	a1,0
    80003e52:	854a                	mv	a0,s2
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	c46080e7          	jalr	-954(ra) # 80003a9a <writei>
    80003e5c:	872a                	mv	a4,a0
    80003e5e:	47c1                	li	a5,16
  return 0;
    80003e60:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e62:	02f71863          	bne	a4,a5,80003e92 <dirlink+0xb2>
}
    80003e66:	70e2                	ld	ra,56(sp)
    80003e68:	7442                	ld	s0,48(sp)
    80003e6a:	74a2                	ld	s1,40(sp)
    80003e6c:	7902                	ld	s2,32(sp)
    80003e6e:	69e2                	ld	s3,24(sp)
    80003e70:	6a42                	ld	s4,16(sp)
    80003e72:	6121                	addi	sp,sp,64
    80003e74:	8082                	ret
    iput(ip);
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	a32080e7          	jalr	-1486(ra) # 800038a8 <iput>
    return -1;
    80003e7e:	557d                	li	a0,-1
    80003e80:	b7dd                	j	80003e66 <dirlink+0x86>
      panic("dirlink read");
    80003e82:	00004517          	auipc	a0,0x4
    80003e86:	70650513          	addi	a0,a0,1798 # 80008588 <syscalls+0x1c8>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6be080e7          	jalr	1726(ra) # 80000548 <panic>
    panic("dirlink");
    80003e92:	00005517          	auipc	a0,0x5
    80003e96:	81650513          	addi	a0,a0,-2026 # 800086a8 <syscalls+0x2e8>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6ae080e7          	jalr	1710(ra) # 80000548 <panic>

0000000080003ea2 <namei>:

struct inode*
namei(char *path)
{
    80003ea2:	1101                	addi	sp,sp,-32
    80003ea4:	ec06                	sd	ra,24(sp)
    80003ea6:	e822                	sd	s0,16(sp)
    80003ea8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eaa:	fe040613          	addi	a2,s0,-32
    80003eae:	4581                	li	a1,0
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	dd0080e7          	jalr	-560(ra) # 80003c80 <namex>
}
    80003eb8:	60e2                	ld	ra,24(sp)
    80003eba:	6442                	ld	s0,16(sp)
    80003ebc:	6105                	addi	sp,sp,32
    80003ebe:	8082                	ret

0000000080003ec0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ec0:	1141                	addi	sp,sp,-16
    80003ec2:	e406                	sd	ra,8(sp)
    80003ec4:	e022                	sd	s0,0(sp)
    80003ec6:	0800                	addi	s0,sp,16
    80003ec8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eca:	4585                	li	a1,1
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	db4080e7          	jalr	-588(ra) # 80003c80 <namex>
}
    80003ed4:	60a2                	ld	ra,8(sp)
    80003ed6:	6402                	ld	s0,0(sp)
    80003ed8:	0141                	addi	sp,sp,16
    80003eda:	8082                	ret

0000000080003edc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	e426                	sd	s1,8(sp)
    80003ee4:	e04a                	sd	s2,0(sp)
    80003ee6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ee8:	0001e917          	auipc	s2,0x1e
    80003eec:	a2090913          	addi	s2,s2,-1504 # 80021908 <log>
    80003ef0:	01892583          	lw	a1,24(s2)
    80003ef4:	02892503          	lw	a0,40(s2)
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	ff4080e7          	jalr	-12(ra) # 80002eec <bread>
    80003f00:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f02:	02c92683          	lw	a3,44(s2)
    80003f06:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f08:	02d05763          	blez	a3,80003f36 <write_head+0x5a>
    80003f0c:	0001e797          	auipc	a5,0x1e
    80003f10:	a2c78793          	addi	a5,a5,-1492 # 80021938 <log+0x30>
    80003f14:	05c50713          	addi	a4,a0,92
    80003f18:	36fd                	addiw	a3,a3,-1
    80003f1a:	1682                	slli	a3,a3,0x20
    80003f1c:	9281                	srli	a3,a3,0x20
    80003f1e:	068a                	slli	a3,a3,0x2
    80003f20:	0001e617          	auipc	a2,0x1e
    80003f24:	a1c60613          	addi	a2,a2,-1508 # 8002193c <log+0x34>
    80003f28:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f2a:	4390                	lw	a2,0(a5)
    80003f2c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f2e:	0791                	addi	a5,a5,4
    80003f30:	0711                	addi	a4,a4,4
    80003f32:	fed79ce3          	bne	a5,a3,80003f2a <write_head+0x4e>
  }
  bwrite(buf);
    80003f36:	8526                	mv	a0,s1
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	0a6080e7          	jalr	166(ra) # 80002fde <bwrite>
  brelse(buf);
    80003f40:	8526                	mv	a0,s1
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	0da080e7          	jalr	218(ra) # 8000301c <brelse>
}
    80003f4a:	60e2                	ld	ra,24(sp)
    80003f4c:	6442                	ld	s0,16(sp)
    80003f4e:	64a2                	ld	s1,8(sp)
    80003f50:	6902                	ld	s2,0(sp)
    80003f52:	6105                	addi	sp,sp,32
    80003f54:	8082                	ret

0000000080003f56 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f56:	0001e797          	auipc	a5,0x1e
    80003f5a:	9de7a783          	lw	a5,-1570(a5) # 80021934 <log+0x2c>
    80003f5e:	0af05663          	blez	a5,8000400a <install_trans+0xb4>
{
    80003f62:	7139                	addi	sp,sp,-64
    80003f64:	fc06                	sd	ra,56(sp)
    80003f66:	f822                	sd	s0,48(sp)
    80003f68:	f426                	sd	s1,40(sp)
    80003f6a:	f04a                	sd	s2,32(sp)
    80003f6c:	ec4e                	sd	s3,24(sp)
    80003f6e:	e852                	sd	s4,16(sp)
    80003f70:	e456                	sd	s5,8(sp)
    80003f72:	0080                	addi	s0,sp,64
    80003f74:	0001ea97          	auipc	s5,0x1e
    80003f78:	9c4a8a93          	addi	s5,s5,-1596 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f7c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f7e:	0001e997          	auipc	s3,0x1e
    80003f82:	98a98993          	addi	s3,s3,-1654 # 80021908 <log>
    80003f86:	0189a583          	lw	a1,24(s3)
    80003f8a:	014585bb          	addw	a1,a1,s4
    80003f8e:	2585                	addiw	a1,a1,1
    80003f90:	0289a503          	lw	a0,40(s3)
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	f58080e7          	jalr	-168(ra) # 80002eec <bread>
    80003f9c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f9e:	000aa583          	lw	a1,0(s5)
    80003fa2:	0289a503          	lw	a0,40(s3)
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	f46080e7          	jalr	-186(ra) # 80002eec <bread>
    80003fae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fb0:	40000613          	li	a2,1024
    80003fb4:	05890593          	addi	a1,s2,88
    80003fb8:	05850513          	addi	a0,a0,88
    80003fbc:	ffffd097          	auipc	ra,0xffffd
    80003fc0:	db0080e7          	jalr	-592(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	018080e7          	jalr	24(ra) # 80002fde <bwrite>
    bunpin(dbuf);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	126080e7          	jalr	294(ra) # 800030f6 <bunpin>
    brelse(lbuf);
    80003fd8:	854a                	mv	a0,s2
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	042080e7          	jalr	66(ra) # 8000301c <brelse>
    brelse(dbuf);
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	038080e7          	jalr	56(ra) # 8000301c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fec:	2a05                	addiw	s4,s4,1
    80003fee:	0a91                	addi	s5,s5,4
    80003ff0:	02c9a783          	lw	a5,44(s3)
    80003ff4:	f8fa49e3          	blt	s4,a5,80003f86 <install_trans+0x30>
}
    80003ff8:	70e2                	ld	ra,56(sp)
    80003ffa:	7442                	ld	s0,48(sp)
    80003ffc:	74a2                	ld	s1,40(sp)
    80003ffe:	7902                	ld	s2,32(sp)
    80004000:	69e2                	ld	s3,24(sp)
    80004002:	6a42                	ld	s4,16(sp)
    80004004:	6aa2                	ld	s5,8(sp)
    80004006:	6121                	addi	sp,sp,64
    80004008:	8082                	ret
    8000400a:	8082                	ret

000000008000400c <initlog>:
{
    8000400c:	7179                	addi	sp,sp,-48
    8000400e:	f406                	sd	ra,40(sp)
    80004010:	f022                	sd	s0,32(sp)
    80004012:	ec26                	sd	s1,24(sp)
    80004014:	e84a                	sd	s2,16(sp)
    80004016:	e44e                	sd	s3,8(sp)
    80004018:	1800                	addi	s0,sp,48
    8000401a:	892a                	mv	s2,a0
    8000401c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000401e:	0001e497          	auipc	s1,0x1e
    80004022:	8ea48493          	addi	s1,s1,-1814 # 80021908 <log>
    80004026:	00004597          	auipc	a1,0x4
    8000402a:	57258593          	addi	a1,a1,1394 # 80008598 <syscalls+0x1d8>
    8000402e:	8526                	mv	a0,s1
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	b50080e7          	jalr	-1200(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004038:	0149a583          	lw	a1,20(s3)
    8000403c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000403e:	0109a783          	lw	a5,16(s3)
    80004042:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004044:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004048:	854a                	mv	a0,s2
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	ea2080e7          	jalr	-350(ra) # 80002eec <bread>
  log.lh.n = lh->n;
    80004052:	4d3c                	lw	a5,88(a0)
    80004054:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004056:	02f05563          	blez	a5,80004080 <initlog+0x74>
    8000405a:	05c50713          	addi	a4,a0,92
    8000405e:	0001e697          	auipc	a3,0x1e
    80004062:	8da68693          	addi	a3,a3,-1830 # 80021938 <log+0x30>
    80004066:	37fd                	addiw	a5,a5,-1
    80004068:	1782                	slli	a5,a5,0x20
    8000406a:	9381                	srli	a5,a5,0x20
    8000406c:	078a                	slli	a5,a5,0x2
    8000406e:	06050613          	addi	a2,a0,96
    80004072:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004074:	4310                	lw	a2,0(a4)
    80004076:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004078:	0711                	addi	a4,a4,4
    8000407a:	0691                	addi	a3,a3,4
    8000407c:	fef71ce3          	bne	a4,a5,80004074 <initlog+0x68>
  brelse(buf);
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	f9c080e7          	jalr	-100(ra) # 8000301c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	ece080e7          	jalr	-306(ra) # 80003f56 <install_trans>
  log.lh.n = 0;
    80004090:	0001e797          	auipc	a5,0x1e
    80004094:	8a07a223          	sw	zero,-1884(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	e44080e7          	jalr	-444(ra) # 80003edc <write_head>
}
    800040a0:	70a2                	ld	ra,40(sp)
    800040a2:	7402                	ld	s0,32(sp)
    800040a4:	64e2                	ld	s1,24(sp)
    800040a6:	6942                	ld	s2,16(sp)
    800040a8:	69a2                	ld	s3,8(sp)
    800040aa:	6145                	addi	sp,sp,48
    800040ac:	8082                	ret

00000000800040ae <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ae:	1101                	addi	sp,sp,-32
    800040b0:	ec06                	sd	ra,24(sp)
    800040b2:	e822                	sd	s0,16(sp)
    800040b4:	e426                	sd	s1,8(sp)
    800040b6:	e04a                	sd	s2,0(sp)
    800040b8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040ba:	0001e517          	auipc	a0,0x1e
    800040be:	84e50513          	addi	a0,a0,-1970 # 80021908 <log>
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	b4e080e7          	jalr	-1202(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    800040ca:	0001e497          	auipc	s1,0x1e
    800040ce:	83e48493          	addi	s1,s1,-1986 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d2:	4979                	li	s2,30
    800040d4:	a039                	j	800040e2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040d6:	85a6                	mv	a1,s1
    800040d8:	8526                	mv	a0,s1
    800040da:	ffffe097          	auipc	ra,0xffffe
    800040de:	16e080e7          	jalr	366(ra) # 80002248 <sleep>
    if(log.committing){
    800040e2:	50dc                	lw	a5,36(s1)
    800040e4:	fbed                	bnez	a5,800040d6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040e6:	509c                	lw	a5,32(s1)
    800040e8:	0017871b          	addiw	a4,a5,1
    800040ec:	0007069b          	sext.w	a3,a4
    800040f0:	0027179b          	slliw	a5,a4,0x2
    800040f4:	9fb9                	addw	a5,a5,a4
    800040f6:	0017979b          	slliw	a5,a5,0x1
    800040fa:	54d8                	lw	a4,44(s1)
    800040fc:	9fb9                	addw	a5,a5,a4
    800040fe:	00f95963          	bge	s2,a5,80004110 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004102:	85a6                	mv	a1,s1
    80004104:	8526                	mv	a0,s1
    80004106:	ffffe097          	auipc	ra,0xffffe
    8000410a:	142080e7          	jalr	322(ra) # 80002248 <sleep>
    8000410e:	bfd1                	j	800040e2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004110:	0001d517          	auipc	a0,0x1d
    80004114:	7f850513          	addi	a0,a0,2040 # 80021908 <log>
    80004118:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	baa080e7          	jalr	-1110(ra) # 80000cc4 <release>
      break;
    }
  }
}
    80004122:	60e2                	ld	ra,24(sp)
    80004124:	6442                	ld	s0,16(sp)
    80004126:	64a2                	ld	s1,8(sp)
    80004128:	6902                	ld	s2,0(sp)
    8000412a:	6105                	addi	sp,sp,32
    8000412c:	8082                	ret

000000008000412e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000412e:	7139                	addi	sp,sp,-64
    80004130:	fc06                	sd	ra,56(sp)
    80004132:	f822                	sd	s0,48(sp)
    80004134:	f426                	sd	s1,40(sp)
    80004136:	f04a                	sd	s2,32(sp)
    80004138:	ec4e                	sd	s3,24(sp)
    8000413a:	e852                	sd	s4,16(sp)
    8000413c:	e456                	sd	s5,8(sp)
    8000413e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004140:	0001d497          	auipc	s1,0x1d
    80004144:	7c848493          	addi	s1,s1,1992 # 80021908 <log>
    80004148:	8526                	mv	a0,s1
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	ac6080e7          	jalr	-1338(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004152:	509c                	lw	a5,32(s1)
    80004154:	37fd                	addiw	a5,a5,-1
    80004156:	0007891b          	sext.w	s2,a5
    8000415a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000415c:	50dc                	lw	a5,36(s1)
    8000415e:	efb9                	bnez	a5,800041bc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004160:	06091663          	bnez	s2,800041cc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004164:	0001d497          	auipc	s1,0x1d
    80004168:	7a448493          	addi	s1,s1,1956 # 80021908 <log>
    8000416c:	4785                	li	a5,1
    8000416e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	b52080e7          	jalr	-1198(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417a:	54dc                	lw	a5,44(s1)
    8000417c:	06f04763          	bgtz	a5,800041ea <end_op+0xbc>
    acquire(&log.lock);
    80004180:	0001d497          	auipc	s1,0x1d
    80004184:	78848493          	addi	s1,s1,1928 # 80021908 <log>
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	a86080e7          	jalr	-1402(ra) # 80000c10 <acquire>
    log.committing = 0;
    80004192:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004196:	8526                	mv	a0,s1
    80004198:	ffffe097          	auipc	ra,0xffffe
    8000419c:	236080e7          	jalr	566(ra) # 800023ce <wakeup>
    release(&log.lock);
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	b22080e7          	jalr	-1246(ra) # 80000cc4 <release>
}
    800041aa:	70e2                	ld	ra,56(sp)
    800041ac:	7442                	ld	s0,48(sp)
    800041ae:	74a2                	ld	s1,40(sp)
    800041b0:	7902                	ld	s2,32(sp)
    800041b2:	69e2                	ld	s3,24(sp)
    800041b4:	6a42                	ld	s4,16(sp)
    800041b6:	6aa2                	ld	s5,8(sp)
    800041b8:	6121                	addi	sp,sp,64
    800041ba:	8082                	ret
    panic("log.committing");
    800041bc:	00004517          	auipc	a0,0x4
    800041c0:	3e450513          	addi	a0,a0,996 # 800085a0 <syscalls+0x1e0>
    800041c4:	ffffc097          	auipc	ra,0xffffc
    800041c8:	384080e7          	jalr	900(ra) # 80000548 <panic>
    wakeup(&log);
    800041cc:	0001d497          	auipc	s1,0x1d
    800041d0:	73c48493          	addi	s1,s1,1852 # 80021908 <log>
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	1f8080e7          	jalr	504(ra) # 800023ce <wakeup>
  release(&log.lock);
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	ae4080e7          	jalr	-1308(ra) # 80000cc4 <release>
  if(do_commit){
    800041e8:	b7c9                	j	800041aa <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ea:	0001da97          	auipc	s5,0x1d
    800041ee:	74ea8a93          	addi	s5,s5,1870 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f2:	0001da17          	auipc	s4,0x1d
    800041f6:	716a0a13          	addi	s4,s4,1814 # 80021908 <log>
    800041fa:	018a2583          	lw	a1,24(s4)
    800041fe:	012585bb          	addw	a1,a1,s2
    80004202:	2585                	addiw	a1,a1,1
    80004204:	028a2503          	lw	a0,40(s4)
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	ce4080e7          	jalr	-796(ra) # 80002eec <bread>
    80004210:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004212:	000aa583          	lw	a1,0(s5)
    80004216:	028a2503          	lw	a0,40(s4)
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	cd2080e7          	jalr	-814(ra) # 80002eec <bread>
    80004222:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004224:	40000613          	li	a2,1024
    80004228:	05850593          	addi	a1,a0,88
    8000422c:	05848513          	addi	a0,s1,88
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	b3c080e7          	jalr	-1220(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004238:	8526                	mv	a0,s1
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	da4080e7          	jalr	-604(ra) # 80002fde <bwrite>
    brelse(from);
    80004242:	854e                	mv	a0,s3
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	dd8080e7          	jalr	-552(ra) # 8000301c <brelse>
    brelse(to);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	dce080e7          	jalr	-562(ra) # 8000301c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	2905                	addiw	s2,s2,1
    80004258:	0a91                	addi	s5,s5,4
    8000425a:	02ca2783          	lw	a5,44(s4)
    8000425e:	f8f94ee3          	blt	s2,a5,800041fa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004262:	00000097          	auipc	ra,0x0
    80004266:	c7a080e7          	jalr	-902(ra) # 80003edc <write_head>
    install_trans(); // Now install writes to home locations
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	cec080e7          	jalr	-788(ra) # 80003f56 <install_trans>
    log.lh.n = 0;
    80004272:	0001d797          	auipc	a5,0x1d
    80004276:	6c07a123          	sw	zero,1730(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	c62080e7          	jalr	-926(ra) # 80003edc <write_head>
    80004282:	bdfd                	j	80004180 <end_op+0x52>

0000000080004284 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004284:	1101                	addi	sp,sp,-32
    80004286:	ec06                	sd	ra,24(sp)
    80004288:	e822                	sd	s0,16(sp)
    8000428a:	e426                	sd	s1,8(sp)
    8000428c:	e04a                	sd	s2,0(sp)
    8000428e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004290:	0001d717          	auipc	a4,0x1d
    80004294:	6a472703          	lw	a4,1700(a4) # 80021934 <log+0x2c>
    80004298:	47f5                	li	a5,29
    8000429a:	08e7c063          	blt	a5,a4,8000431a <log_write+0x96>
    8000429e:	84aa                	mv	s1,a0
    800042a0:	0001d797          	auipc	a5,0x1d
    800042a4:	6847a783          	lw	a5,1668(a5) # 80021924 <log+0x1c>
    800042a8:	37fd                	addiw	a5,a5,-1
    800042aa:	06f75863          	bge	a4,a5,8000431a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042ae:	0001d797          	auipc	a5,0x1d
    800042b2:	67a7a783          	lw	a5,1658(a5) # 80021928 <log+0x20>
    800042b6:	06f05a63          	blez	a5,8000432a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042ba:	0001d917          	auipc	s2,0x1d
    800042be:	64e90913          	addi	s2,s2,1614 # 80021908 <log>
    800042c2:	854a                	mv	a0,s2
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	94c080e7          	jalr	-1716(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042cc:	02c92603          	lw	a2,44(s2)
    800042d0:	06c05563          	blez	a2,8000433a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042d4:	44cc                	lw	a1,12(s1)
    800042d6:	0001d717          	auipc	a4,0x1d
    800042da:	66270713          	addi	a4,a4,1634 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042e0:	4314                	lw	a3,0(a4)
    800042e2:	04b68d63          	beq	a3,a1,8000433c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042e6:	2785                	addiw	a5,a5,1
    800042e8:	0711                	addi	a4,a4,4
    800042ea:	fec79be3          	bne	a5,a2,800042e0 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ee:	0621                	addi	a2,a2,8
    800042f0:	060a                	slli	a2,a2,0x2
    800042f2:	0001d797          	auipc	a5,0x1d
    800042f6:	61678793          	addi	a5,a5,1558 # 80021908 <log>
    800042fa:	963e                	add	a2,a2,a5
    800042fc:	44dc                	lw	a5,12(s1)
    800042fe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004300:	8526                	mv	a0,s1
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	db8080e7          	jalr	-584(ra) # 800030ba <bpin>
    log.lh.n++;
    8000430a:	0001d717          	auipc	a4,0x1d
    8000430e:	5fe70713          	addi	a4,a4,1534 # 80021908 <log>
    80004312:	575c                	lw	a5,44(a4)
    80004314:	2785                	addiw	a5,a5,1
    80004316:	d75c                	sw	a5,44(a4)
    80004318:	a83d                	j	80004356 <log_write+0xd2>
    panic("too big a transaction");
    8000431a:	00004517          	auipc	a0,0x4
    8000431e:	29650513          	addi	a0,a0,662 # 800085b0 <syscalls+0x1f0>
    80004322:	ffffc097          	auipc	ra,0xffffc
    80004326:	226080e7          	jalr	550(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000432a:	00004517          	auipc	a0,0x4
    8000432e:	29e50513          	addi	a0,a0,670 # 800085c8 <syscalls+0x208>
    80004332:	ffffc097          	auipc	ra,0xffffc
    80004336:	216080e7          	jalr	534(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000433a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000433c:	00878713          	addi	a4,a5,8
    80004340:	00271693          	slli	a3,a4,0x2
    80004344:	0001d717          	auipc	a4,0x1d
    80004348:	5c470713          	addi	a4,a4,1476 # 80021908 <log>
    8000434c:	9736                	add	a4,a4,a3
    8000434e:	44d4                	lw	a3,12(s1)
    80004350:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004352:	faf607e3          	beq	a2,a5,80004300 <log_write+0x7c>
  }
  release(&log.lock);
    80004356:	0001d517          	auipc	a0,0x1d
    8000435a:	5b250513          	addi	a0,a0,1458 # 80021908 <log>
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	966080e7          	jalr	-1690(ra) # 80000cc4 <release>
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	64a2                	ld	s1,8(sp)
    8000436c:	6902                	ld	s2,0(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
    8000437e:	84aa                	mv	s1,a0
    80004380:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004382:	00004597          	auipc	a1,0x4
    80004386:	26658593          	addi	a1,a1,614 # 800085e8 <syscalls+0x228>
    8000438a:	0521                	addi	a0,a0,8
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	7f4080e7          	jalr	2036(ra) # 80000b80 <initlock>
  lk->name = name;
    80004394:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004398:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000439c:	0204a423          	sw	zero,40(s1)
}
    800043a0:	60e2                	ld	ra,24(sp)
    800043a2:	6442                	ld	s0,16(sp)
    800043a4:	64a2                	ld	s1,8(sp)
    800043a6:	6902                	ld	s2,0(sp)
    800043a8:	6105                	addi	sp,sp,32
    800043aa:	8082                	ret

00000000800043ac <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ac:	1101                	addi	sp,sp,-32
    800043ae:	ec06                	sd	ra,24(sp)
    800043b0:	e822                	sd	s0,16(sp)
    800043b2:	e426                	sd	s1,8(sp)
    800043b4:	e04a                	sd	s2,0(sp)
    800043b6:	1000                	addi	s0,sp,32
    800043b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ba:	00850913          	addi	s2,a0,8
    800043be:	854a                	mv	a0,s2
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	850080e7          	jalr	-1968(ra) # 80000c10 <acquire>
  while (lk->locked) {
    800043c8:	409c                	lw	a5,0(s1)
    800043ca:	cb89                	beqz	a5,800043dc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043cc:	85ca                	mv	a1,s2
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	e78080e7          	jalr	-392(ra) # 80002248 <sleep>
  while (lk->locked) {
    800043d8:	409c                	lw	a5,0(s1)
    800043da:	fbed                	bnez	a5,800043cc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043dc:	4785                	li	a5,1
    800043de:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	658080e7          	jalr	1624(ra) # 80001a38 <myproc>
    800043e8:	5d1c                	lw	a5,56(a0)
    800043ea:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043ec:	854a                	mv	a0,s2
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	8d6080e7          	jalr	-1834(ra) # 80000cc4 <release>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004402:	1101                	addi	sp,sp,-32
    80004404:	ec06                	sd	ra,24(sp)
    80004406:	e822                	sd	s0,16(sp)
    80004408:	e426                	sd	s1,8(sp)
    8000440a:	e04a                	sd	s2,0(sp)
    8000440c:	1000                	addi	s0,sp,32
    8000440e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004410:	00850913          	addi	s2,a0,8
    80004414:	854a                	mv	a0,s2
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7fa080e7          	jalr	2042(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000441e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004422:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	fa6080e7          	jalr	-90(ra) # 800023ce <wakeup>
  release(&lk->lk);
    80004430:	854a                	mv	a0,s2
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	892080e7          	jalr	-1902(ra) # 80000cc4 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004446:	7179                	addi	sp,sp,-48
    80004448:	f406                	sd	ra,40(sp)
    8000444a:	f022                	sd	s0,32(sp)
    8000444c:	ec26                	sd	s1,24(sp)
    8000444e:	e84a                	sd	s2,16(sp)
    80004450:	e44e                	sd	s3,8(sp)
    80004452:	1800                	addi	s0,sp,48
    80004454:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004456:	00850913          	addi	s2,a0,8
    8000445a:	854a                	mv	a0,s2
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	7b4080e7          	jalr	1972(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004464:	409c                	lw	a5,0(s1)
    80004466:	ef99                	bnez	a5,80004484 <holdingsleep+0x3e>
    80004468:	4481                	li	s1,0
  release(&lk->lk);
    8000446a:	854a                	mv	a0,s2
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	858080e7          	jalr	-1960(ra) # 80000cc4 <release>
  return r;
}
    80004474:	8526                	mv	a0,s1
    80004476:	70a2                	ld	ra,40(sp)
    80004478:	7402                	ld	s0,32(sp)
    8000447a:	64e2                	ld	s1,24(sp)
    8000447c:	6942                	ld	s2,16(sp)
    8000447e:	69a2                	ld	s3,8(sp)
    80004480:	6145                	addi	sp,sp,48
    80004482:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004484:	0284a983          	lw	s3,40(s1)
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	5b0080e7          	jalr	1456(ra) # 80001a38 <myproc>
    80004490:	5d04                	lw	s1,56(a0)
    80004492:	413484b3          	sub	s1,s1,s3
    80004496:	0014b493          	seqz	s1,s1
    8000449a:	bfc1                	j	8000446a <holdingsleep+0x24>

000000008000449c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000449c:	1141                	addi	sp,sp,-16
    8000449e:	e406                	sd	ra,8(sp)
    800044a0:	e022                	sd	s0,0(sp)
    800044a2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044a4:	00004597          	auipc	a1,0x4
    800044a8:	15458593          	addi	a1,a1,340 # 800085f8 <syscalls+0x238>
    800044ac:	0001d517          	auipc	a0,0x1d
    800044b0:	5a450513          	addi	a0,a0,1444 # 80021a50 <ftable>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	6cc080e7          	jalr	1740(ra) # 80000b80 <initlock>
}
    800044bc:	60a2                	ld	ra,8(sp)
    800044be:	6402                	ld	s0,0(sp)
    800044c0:	0141                	addi	sp,sp,16
    800044c2:	8082                	ret

00000000800044c4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ce:	0001d517          	auipc	a0,0x1d
    800044d2:	58250513          	addi	a0,a0,1410 # 80021a50 <ftable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	73a080e7          	jalr	1850(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044de:	0001d497          	auipc	s1,0x1d
    800044e2:	58a48493          	addi	s1,s1,1418 # 80021a68 <ftable+0x18>
    800044e6:	0001e717          	auipc	a4,0x1e
    800044ea:	52270713          	addi	a4,a4,1314 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800044ee:	40dc                	lw	a5,4(s1)
    800044f0:	cf99                	beqz	a5,8000450e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f2:	02848493          	addi	s1,s1,40
    800044f6:	fee49ce3          	bne	s1,a4,800044ee <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	55650513          	addi	a0,a0,1366 # 80021a50 <ftable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	7c2080e7          	jalr	1986(ra) # 80000cc4 <release>
  return 0;
    8000450a:	4481                	li	s1,0
    8000450c:	a819                	j	80004522 <filealloc+0x5e>
      f->ref = 1;
    8000450e:	4785                	li	a5,1
    80004510:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	53e50513          	addi	a0,a0,1342 # 80021a50 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	7aa080e7          	jalr	1962(ra) # 80000cc4 <release>
}
    80004522:	8526                	mv	a0,s1
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000452e:	1101                	addi	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	1000                	addi	s0,sp,32
    80004538:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	51650513          	addi	a0,a0,1302 # 80021a50 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	6ce080e7          	jalr	1742(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000454a:	40dc                	lw	a5,4(s1)
    8000454c:	02f05263          	blez	a5,80004570 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004550:	2785                	addiw	a5,a5,1
    80004552:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	4fc50513          	addi	a0,a0,1276 # 80021a50 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	768080e7          	jalr	1896(ra) # 80000cc4 <release>
  return f;
}
    80004564:	8526                	mv	a0,s1
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret
    panic("filedup");
    80004570:	00004517          	auipc	a0,0x4
    80004574:	09050513          	addi	a0,a0,144 # 80008600 <syscalls+0x240>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	fd0080e7          	jalr	-48(ra) # 80000548 <panic>

0000000080004580 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004580:	7139                	addi	sp,sp,-64
    80004582:	fc06                	sd	ra,56(sp)
    80004584:	f822                	sd	s0,48(sp)
    80004586:	f426                	sd	s1,40(sp)
    80004588:	f04a                	sd	s2,32(sp)
    8000458a:	ec4e                	sd	s3,24(sp)
    8000458c:	e852                	sd	s4,16(sp)
    8000458e:	e456                	sd	s5,8(sp)
    80004590:	0080                	addi	s0,sp,64
    80004592:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004594:	0001d517          	auipc	a0,0x1d
    80004598:	4bc50513          	addi	a0,a0,1212 # 80021a50 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	674080e7          	jalr	1652(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045a4:	40dc                	lw	a5,4(s1)
    800045a6:	06f05163          	blez	a5,80004608 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045aa:	37fd                	addiw	a5,a5,-1
    800045ac:	0007871b          	sext.w	a4,a5
    800045b0:	c0dc                	sw	a5,4(s1)
    800045b2:	06e04363          	bgtz	a4,80004618 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045b6:	0004a903          	lw	s2,0(s1)
    800045ba:	0094ca83          	lbu	s5,9(s1)
    800045be:	0104ba03          	ld	s4,16(s1)
    800045c2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045c6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ca:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	48250513          	addi	a0,a0,1154 # 80021a50 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6ee080e7          	jalr	1774(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800045de:	4785                	li	a5,1
    800045e0:	04f90d63          	beq	s2,a5,8000463a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045e4:	3979                	addiw	s2,s2,-2
    800045e6:	4785                	li	a5,1
    800045e8:	0527e063          	bltu	a5,s2,80004628 <fileclose+0xa8>
    begin_op();
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	ac2080e7          	jalr	-1342(ra) # 800040ae <begin_op>
    iput(ff.ip);
    800045f4:	854e                	mv	a0,s3
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	2b2080e7          	jalr	690(ra) # 800038a8 <iput>
    end_op();
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	b30080e7          	jalr	-1232(ra) # 8000412e <end_op>
    80004606:	a00d                	j	80004628 <fileclose+0xa8>
    panic("fileclose");
    80004608:	00004517          	auipc	a0,0x4
    8000460c:	00050513          	mv	a0,a0
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	f38080e7          	jalr	-200(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	43850513          	addi	a0,a0,1080 # 80021a50 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	6a4080e7          	jalr	1700(ra) # 80000cc4 <release>
  }
}
    80004628:	70e2                	ld	ra,56(sp)
    8000462a:	7442                	ld	s0,48(sp)
    8000462c:	74a2                	ld	s1,40(sp)
    8000462e:	7902                	ld	s2,32(sp)
    80004630:	69e2                	ld	s3,24(sp)
    80004632:	6a42                	ld	s4,16(sp)
    80004634:	6aa2                	ld	s5,8(sp)
    80004636:	6121                	addi	sp,sp,64
    80004638:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000463a:	85d6                	mv	a1,s5
    8000463c:	8552                	mv	a0,s4
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	372080e7          	jalr	882(ra) # 800049b0 <pipeclose>
    80004646:	b7cd                	j	80004628 <fileclose+0xa8>

0000000080004648 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004648:	715d                	addi	sp,sp,-80
    8000464a:	e486                	sd	ra,72(sp)
    8000464c:	e0a2                	sd	s0,64(sp)
    8000464e:	fc26                	sd	s1,56(sp)
    80004650:	f84a                	sd	s2,48(sp)
    80004652:	f44e                	sd	s3,40(sp)
    80004654:	0880                	addi	s0,sp,80
    80004656:	84aa                	mv	s1,a0
    80004658:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000465a:	ffffd097          	auipc	ra,0xffffd
    8000465e:	3de080e7          	jalr	990(ra) # 80001a38 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004662:	409c                	lw	a5,0(s1)
    80004664:	37f9                	addiw	a5,a5,-2
    80004666:	4705                	li	a4,1
    80004668:	04f76763          	bltu	a4,a5,800046b6 <filestat+0x6e>
    8000466c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000466e:	6c88                	ld	a0,24(s1)
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	07e080e7          	jalr	126(ra) # 800036ee <ilock>
    stati(f->ip, &st);
    80004678:	fb840593          	addi	a1,s0,-72
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	2fa080e7          	jalr	762(ra) # 80003978 <stati>
    iunlock(f->ip);
    80004686:	6c88                	ld	a0,24(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	128080e7          	jalr	296(ra) # 800037b0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004690:	46e1                	li	a3,24
    80004692:	fb840613          	addi	a2,s0,-72
    80004696:	85ce                	mv	a1,s3
    80004698:	05093503          	ld	a0,80(s2)
    8000469c:	ffffd097          	auipc	ra,0xffffd
    800046a0:	090080e7          	jalr	144(ra) # 8000172c <copyout>
    800046a4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a8:	60a6                	ld	ra,72(sp)
    800046aa:	6406                	ld	s0,64(sp)
    800046ac:	74e2                	ld	s1,56(sp)
    800046ae:	7942                	ld	s2,48(sp)
    800046b0:	79a2                	ld	s3,40(sp)
    800046b2:	6161                	addi	sp,sp,80
    800046b4:	8082                	ret
  return -1;
    800046b6:	557d                	li	a0,-1
    800046b8:	bfc5                	j	800046a8 <filestat+0x60>

00000000800046ba <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046ba:	7179                	addi	sp,sp,-48
    800046bc:	f406                	sd	ra,40(sp)
    800046be:	f022                	sd	s0,32(sp)
    800046c0:	ec26                	sd	s1,24(sp)
    800046c2:	e84a                	sd	s2,16(sp)
    800046c4:	e44e                	sd	s3,8(sp)
    800046c6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c8:	00854783          	lbu	a5,8(a0)
    800046cc:	c3d5                	beqz	a5,80004770 <fileread+0xb6>
    800046ce:	84aa                	mv	s1,a0
    800046d0:	89ae                	mv	s3,a1
    800046d2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d4:	411c                	lw	a5,0(a0)
    800046d6:	4705                	li	a4,1
    800046d8:	04e78963          	beq	a5,a4,8000472a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046dc:	470d                	li	a4,3
    800046de:	04e78d63          	beq	a5,a4,80004738 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046e2:	4709                	li	a4,2
    800046e4:	06e79e63          	bne	a5,a4,80004760 <fileread+0xa6>
    ilock(f->ip);
    800046e8:	6d08                	ld	a0,24(a0)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	004080e7          	jalr	4(ra) # 800036ee <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046f2:	874a                	mv	a4,s2
    800046f4:	5094                	lw	a3,32(s1)
    800046f6:	864e                	mv	a2,s3
    800046f8:	4585                	li	a1,1
    800046fa:	6c88                	ld	a0,24(s1)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	2a6080e7          	jalr	678(ra) # 800039a2 <readi>
    80004704:	892a                	mv	s2,a0
    80004706:	00a05563          	blez	a0,80004710 <fileread+0x56>
      f->off += r;
    8000470a:	509c                	lw	a5,32(s1)
    8000470c:	9fa9                	addw	a5,a5,a0
    8000470e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004710:	6c88                	ld	a0,24(s1)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	09e080e7          	jalr	158(ra) # 800037b0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000471a:	854a                	mv	a0,s2
    8000471c:	70a2                	ld	ra,40(sp)
    8000471e:	7402                	ld	s0,32(sp)
    80004720:	64e2                	ld	s1,24(sp)
    80004722:	6942                	ld	s2,16(sp)
    80004724:	69a2                	ld	s3,8(sp)
    80004726:	6145                	addi	sp,sp,48
    80004728:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000472a:	6908                	ld	a0,16(a0)
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	418080e7          	jalr	1048(ra) # 80004b44 <piperead>
    80004734:	892a                	mv	s2,a0
    80004736:	b7d5                	j	8000471a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004738:	02451783          	lh	a5,36(a0)
    8000473c:	03079693          	slli	a3,a5,0x30
    80004740:	92c1                	srli	a3,a3,0x30
    80004742:	4725                	li	a4,9
    80004744:	02d76863          	bltu	a4,a3,80004774 <fileread+0xba>
    80004748:	0792                	slli	a5,a5,0x4
    8000474a:	0001d717          	auipc	a4,0x1d
    8000474e:	26670713          	addi	a4,a4,614 # 800219b0 <devsw>
    80004752:	97ba                	add	a5,a5,a4
    80004754:	639c                	ld	a5,0(a5)
    80004756:	c38d                	beqz	a5,80004778 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004758:	4505                	li	a0,1
    8000475a:	9782                	jalr	a5
    8000475c:	892a                	mv	s2,a0
    8000475e:	bf75                	j	8000471a <fileread+0x60>
    panic("fileread");
    80004760:	00004517          	auipc	a0,0x4
    80004764:	eb850513          	addi	a0,a0,-328 # 80008618 <syscalls+0x258>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	de0080e7          	jalr	-544(ra) # 80000548 <panic>
    return -1;
    80004770:	597d                	li	s2,-1
    80004772:	b765                	j	8000471a <fileread+0x60>
      return -1;
    80004774:	597d                	li	s2,-1
    80004776:	b755                	j	8000471a <fileread+0x60>
    80004778:	597d                	li	s2,-1
    8000477a:	b745                	j	8000471a <fileread+0x60>

000000008000477c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000477c:	00954783          	lbu	a5,9(a0)
    80004780:	14078563          	beqz	a5,800048ca <filewrite+0x14e>
{
    80004784:	715d                	addi	sp,sp,-80
    80004786:	e486                	sd	ra,72(sp)
    80004788:	e0a2                	sd	s0,64(sp)
    8000478a:	fc26                	sd	s1,56(sp)
    8000478c:	f84a                	sd	s2,48(sp)
    8000478e:	f44e                	sd	s3,40(sp)
    80004790:	f052                	sd	s4,32(sp)
    80004792:	ec56                	sd	s5,24(sp)
    80004794:	e85a                	sd	s6,16(sp)
    80004796:	e45e                	sd	s7,8(sp)
    80004798:	e062                	sd	s8,0(sp)
    8000479a:	0880                	addi	s0,sp,80
    8000479c:	892a                	mv	s2,a0
    8000479e:	8aae                	mv	s5,a1
    800047a0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a2:	411c                	lw	a5,0(a0)
    800047a4:	4705                	li	a4,1
    800047a6:	02e78263          	beq	a5,a4,800047ca <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047aa:	470d                	li	a4,3
    800047ac:	02e78563          	beq	a5,a4,800047d6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b0:	4709                	li	a4,2
    800047b2:	10e79463          	bne	a5,a4,800048ba <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047b6:	0ec05e63          	blez	a2,800048b2 <filewrite+0x136>
    int i = 0;
    800047ba:	4981                	li	s3,0
    800047bc:	6b05                	lui	s6,0x1
    800047be:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047c2:	6b85                	lui	s7,0x1
    800047c4:	c00b8b9b          	addiw	s7,s7,-1024
    800047c8:	a851                	j	8000485c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047ca:	6908                	ld	a0,16(a0)
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	254080e7          	jalr	596(ra) # 80004a20 <pipewrite>
    800047d4:	a85d                	j	8000488a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047d6:	02451783          	lh	a5,36(a0)
    800047da:	03079693          	slli	a3,a5,0x30
    800047de:	92c1                	srli	a3,a3,0x30
    800047e0:	4725                	li	a4,9
    800047e2:	0ed76663          	bltu	a4,a3,800048ce <filewrite+0x152>
    800047e6:	0792                	slli	a5,a5,0x4
    800047e8:	0001d717          	auipc	a4,0x1d
    800047ec:	1c870713          	addi	a4,a4,456 # 800219b0 <devsw>
    800047f0:	97ba                	add	a5,a5,a4
    800047f2:	679c                	ld	a5,8(a5)
    800047f4:	cff9                	beqz	a5,800048d2 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047f6:	4505                	li	a0,1
    800047f8:	9782                	jalr	a5
    800047fa:	a841                	j	8000488a <filewrite+0x10e>
    800047fc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004800:	00000097          	auipc	ra,0x0
    80004804:	8ae080e7          	jalr	-1874(ra) # 800040ae <begin_op>
      ilock(f->ip);
    80004808:	01893503          	ld	a0,24(s2)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	ee2080e7          	jalr	-286(ra) # 800036ee <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004814:	8762                	mv	a4,s8
    80004816:	02092683          	lw	a3,32(s2)
    8000481a:	01598633          	add	a2,s3,s5
    8000481e:	4585                	li	a1,1
    80004820:	01893503          	ld	a0,24(s2)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	276080e7          	jalr	630(ra) # 80003a9a <writei>
    8000482c:	84aa                	mv	s1,a0
    8000482e:	02a05f63          	blez	a0,8000486c <filewrite+0xf0>
        f->off += r;
    80004832:	02092783          	lw	a5,32(s2)
    80004836:	9fa9                	addw	a5,a5,a0
    80004838:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000483c:	01893503          	ld	a0,24(s2)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	f70080e7          	jalr	-144(ra) # 800037b0 <iunlock>
      end_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8e6080e7          	jalr	-1818(ra) # 8000412e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004850:	049c1963          	bne	s8,s1,800048a2 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004854:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004858:	0349d663          	bge	s3,s4,80004884 <filewrite+0x108>
      int n1 = n - i;
    8000485c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004860:	84be                	mv	s1,a5
    80004862:	2781                	sext.w	a5,a5
    80004864:	f8fb5ce3          	bge	s6,a5,800047fc <filewrite+0x80>
    80004868:	84de                	mv	s1,s7
    8000486a:	bf49                	j	800047fc <filewrite+0x80>
      iunlock(f->ip);
    8000486c:	01893503          	ld	a0,24(s2)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	f40080e7          	jalr	-192(ra) # 800037b0 <iunlock>
      end_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	8b6080e7          	jalr	-1866(ra) # 8000412e <end_op>
      if(r < 0)
    80004880:	fc04d8e3          	bgez	s1,80004850 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004884:	8552                	mv	a0,s4
    80004886:	033a1863          	bne	s4,s3,800048b6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000488a:	60a6                	ld	ra,72(sp)
    8000488c:	6406                	ld	s0,64(sp)
    8000488e:	74e2                	ld	s1,56(sp)
    80004890:	7942                	ld	s2,48(sp)
    80004892:	79a2                	ld	s3,40(sp)
    80004894:	7a02                	ld	s4,32(sp)
    80004896:	6ae2                	ld	s5,24(sp)
    80004898:	6b42                	ld	s6,16(sp)
    8000489a:	6ba2                	ld	s7,8(sp)
    8000489c:	6c02                	ld	s8,0(sp)
    8000489e:	6161                	addi	sp,sp,80
    800048a0:	8082                	ret
        panic("short filewrite");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	d8650513          	addi	a0,a0,-634 # 80008628 <syscalls+0x268>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c9e080e7          	jalr	-866(ra) # 80000548 <panic>
    int i = 0;
    800048b2:	4981                	li	s3,0
    800048b4:	bfc1                	j	80004884 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048b6:	557d                	li	a0,-1
    800048b8:	bfc9                	j	8000488a <filewrite+0x10e>
    panic("filewrite");
    800048ba:	00004517          	auipc	a0,0x4
    800048be:	d7e50513          	addi	a0,a0,-642 # 80008638 <syscalls+0x278>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	c86080e7          	jalr	-890(ra) # 80000548 <panic>
    return -1;
    800048ca:	557d                	li	a0,-1
}
    800048cc:	8082                	ret
      return -1;
    800048ce:	557d                	li	a0,-1
    800048d0:	bf6d                	j	8000488a <filewrite+0x10e>
    800048d2:	557d                	li	a0,-1
    800048d4:	bf5d                	j	8000488a <filewrite+0x10e>

00000000800048d6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d6:	7179                	addi	sp,sp,-48
    800048d8:	f406                	sd	ra,40(sp)
    800048da:	f022                	sd	s0,32(sp)
    800048dc:	ec26                	sd	s1,24(sp)
    800048de:	e84a                	sd	s2,16(sp)
    800048e0:	e44e                	sd	s3,8(sp)
    800048e2:	e052                	sd	s4,0(sp)
    800048e4:	1800                	addi	s0,sp,48
    800048e6:	84aa                	mv	s1,a0
    800048e8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048ea:	0005b023          	sd	zero,0(a1)
    800048ee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	bd2080e7          	jalr	-1070(ra) # 800044c4 <filealloc>
    800048fa:	e088                	sd	a0,0(s1)
    800048fc:	c551                	beqz	a0,80004988 <pipealloc+0xb2>
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	bc6080e7          	jalr	-1082(ra) # 800044c4 <filealloc>
    80004906:	00aa3023          	sd	a0,0(s4)
    8000490a:	c92d                	beqz	a0,8000497c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	214080e7          	jalr	532(ra) # 80000b20 <kalloc>
    80004914:	892a                	mv	s2,a0
    80004916:	c125                	beqz	a0,80004976 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004918:	4985                	li	s3,1
    8000491a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000491e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004922:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004926:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000492a:	00004597          	auipc	a1,0x4
    8000492e:	d1e58593          	addi	a1,a1,-738 # 80008648 <syscalls+0x288>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	24e080e7          	jalr	590(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000494c:	609c                	ld	a5,0(s1)
    8000494e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000495a:	000a3783          	ld	a5,0(s4)
    8000495e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004962:	000a3783          	ld	a5,0(s4)
    80004966:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000496a:	000a3783          	ld	a5,0(s4)
    8000496e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004972:	4501                	li	a0,0
    80004974:	a025                	j	8000499c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004976:	6088                	ld	a0,0(s1)
    80004978:	e501                	bnez	a0,80004980 <pipealloc+0xaa>
    8000497a:	a039                	j	80004988 <pipealloc+0xb2>
    8000497c:	6088                	ld	a0,0(s1)
    8000497e:	c51d                	beqz	a0,800049ac <pipealloc+0xd6>
    fileclose(*f0);
    80004980:	00000097          	auipc	ra,0x0
    80004984:	c00080e7          	jalr	-1024(ra) # 80004580 <fileclose>
  if(*f1)
    80004988:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000498c:	557d                	li	a0,-1
  if(*f1)
    8000498e:	c799                	beqz	a5,8000499c <pipealloc+0xc6>
    fileclose(*f1);
    80004990:	853e                	mv	a0,a5
    80004992:	00000097          	auipc	ra,0x0
    80004996:	bee080e7          	jalr	-1042(ra) # 80004580 <fileclose>
  return -1;
    8000499a:	557d                	li	a0,-1
}
    8000499c:	70a2                	ld	ra,40(sp)
    8000499e:	7402                	ld	s0,32(sp)
    800049a0:	64e2                	ld	s1,24(sp)
    800049a2:	6942                	ld	s2,16(sp)
    800049a4:	69a2                	ld	s3,8(sp)
    800049a6:	6a02                	ld	s4,0(sp)
    800049a8:	6145                	addi	sp,sp,48
    800049aa:	8082                	ret
  return -1;
    800049ac:	557d                	li	a0,-1
    800049ae:	b7fd                	j	8000499c <pipealloc+0xc6>

00000000800049b0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049b0:	1101                	addi	sp,sp,-32
    800049b2:	ec06                	sd	ra,24(sp)
    800049b4:	e822                	sd	s0,16(sp)
    800049b6:	e426                	sd	s1,8(sp)
    800049b8:	e04a                	sd	s2,0(sp)
    800049ba:	1000                	addi	s0,sp,32
    800049bc:	84aa                	mv	s1,a0
    800049be:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	250080e7          	jalr	592(ra) # 80000c10 <acquire>
  if(writable){
    800049c8:	02090d63          	beqz	s2,80004a02 <pipeclose+0x52>
    pi->writeopen = 0;
    800049cc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049d0:	21848513          	addi	a0,s1,536
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	9fa080e7          	jalr	-1542(ra) # 800023ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049dc:	2204b783          	ld	a5,544(s1)
    800049e0:	eb95                	bnez	a5,80004a14 <pipeclose+0x64>
    release(&pi->lock);
    800049e2:	8526                	mv	a0,s1
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	2e0080e7          	jalr	736(ra) # 80000cc4 <release>
    kfree((char*)pi);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	036080e7          	jalr	54(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    800049f6:	60e2                	ld	ra,24(sp)
    800049f8:	6442                	ld	s0,16(sp)
    800049fa:	64a2                	ld	s1,8(sp)
    800049fc:	6902                	ld	s2,0(sp)
    800049fe:	6105                	addi	sp,sp,32
    80004a00:	8082                	ret
    pi->readopen = 0;
    80004a02:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a06:	21c48513          	addi	a0,s1,540
    80004a0a:	ffffe097          	auipc	ra,0xffffe
    80004a0e:	9c4080e7          	jalr	-1596(ra) # 800023ce <wakeup>
    80004a12:	b7e9                	j	800049dc <pipeclose+0x2c>
    release(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	2ae080e7          	jalr	686(ra) # 80000cc4 <release>
}
    80004a1e:	bfe1                	j	800049f6 <pipeclose+0x46>

0000000080004a20 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a20:	7119                	addi	sp,sp,-128
    80004a22:	fc86                	sd	ra,120(sp)
    80004a24:	f8a2                	sd	s0,112(sp)
    80004a26:	f4a6                	sd	s1,104(sp)
    80004a28:	f0ca                	sd	s2,96(sp)
    80004a2a:	ecce                	sd	s3,88(sp)
    80004a2c:	e8d2                	sd	s4,80(sp)
    80004a2e:	e4d6                	sd	s5,72(sp)
    80004a30:	e0da                	sd	s6,64(sp)
    80004a32:	fc5e                	sd	s7,56(sp)
    80004a34:	f862                	sd	s8,48(sp)
    80004a36:	f466                	sd	s9,40(sp)
    80004a38:	f06a                	sd	s10,32(sp)
    80004a3a:	ec6e                	sd	s11,24(sp)
    80004a3c:	0100                	addi	s0,sp,128
    80004a3e:	84aa                	mv	s1,a0
    80004a40:	8cae                	mv	s9,a1
    80004a42:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	ff4080e7          	jalr	-12(ra) # 80001a38 <myproc>
    80004a4c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	1c0080e7          	jalr	448(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004a58:	0d605963          	blez	s6,80004b2a <pipewrite+0x10a>
    80004a5c:	89a6                	mv	s3,s1
    80004a5e:	3b7d                	addiw	s6,s6,-1
    80004a60:	1b02                	slli	s6,s6,0x20
    80004a62:	020b5b13          	srli	s6,s6,0x20
    80004a66:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a68:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6c:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a70:	5dfd                	li	s11,-1
    80004a72:	000b8d1b          	sext.w	s10,s7
    80004a76:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a78:	2184a783          	lw	a5,536(s1)
    80004a7c:	21c4a703          	lw	a4,540(s1)
    80004a80:	2007879b          	addiw	a5,a5,512
    80004a84:	02f71b63          	bne	a4,a5,80004aba <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a88:	2204a783          	lw	a5,544(s1)
    80004a8c:	cbad                	beqz	a5,80004afe <pipewrite+0xde>
    80004a8e:	03092783          	lw	a5,48(s2)
    80004a92:	e7b5                	bnez	a5,80004afe <pipewrite+0xde>
      wakeup(&pi->nread);
    80004a94:	8556                	mv	a0,s5
    80004a96:	ffffe097          	auipc	ra,0xffffe
    80004a9a:	938080e7          	jalr	-1736(ra) # 800023ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a9e:	85ce                	mv	a1,s3
    80004aa0:	8552                	mv	a0,s4
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	7a6080e7          	jalr	1958(ra) # 80002248 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004aaa:	2184a783          	lw	a5,536(s1)
    80004aae:	21c4a703          	lw	a4,540(s1)
    80004ab2:	2007879b          	addiw	a5,a5,512
    80004ab6:	fcf709e3          	beq	a4,a5,80004a88 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aba:	4685                	li	a3,1
    80004abc:	019b8633          	add	a2,s7,s9
    80004ac0:	f8f40593          	addi	a1,s0,-113
    80004ac4:	05093503          	ld	a0,80(s2)
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	cf0080e7          	jalr	-784(ra) # 800017b8 <copyin>
    80004ad0:	05b50e63          	beq	a0,s11,80004b2c <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ad4:	21c4a783          	lw	a5,540(s1)
    80004ad8:	0017871b          	addiw	a4,a5,1
    80004adc:	20e4ae23          	sw	a4,540(s1)
    80004ae0:	1ff7f793          	andi	a5,a5,511
    80004ae4:	97a6                	add	a5,a5,s1
    80004ae6:	f8f44703          	lbu	a4,-113(s0)
    80004aea:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004aee:	001d0c1b          	addiw	s8,s10,1
    80004af2:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004af6:	036b8b63          	beq	s7,s6,80004b2c <pipewrite+0x10c>
    80004afa:	8bbe                	mv	s7,a5
    80004afc:	bf9d                	j	80004a72 <pipewrite+0x52>
        release(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	1c4080e7          	jalr	452(ra) # 80000cc4 <release>
        return -1;
    80004b08:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b0a:	8562                	mv	a0,s8
    80004b0c:	70e6                	ld	ra,120(sp)
    80004b0e:	7446                	ld	s0,112(sp)
    80004b10:	74a6                	ld	s1,104(sp)
    80004b12:	7906                	ld	s2,96(sp)
    80004b14:	69e6                	ld	s3,88(sp)
    80004b16:	6a46                	ld	s4,80(sp)
    80004b18:	6aa6                	ld	s5,72(sp)
    80004b1a:	6b06                	ld	s6,64(sp)
    80004b1c:	7be2                	ld	s7,56(sp)
    80004b1e:	7c42                	ld	s8,48(sp)
    80004b20:	7ca2                	ld	s9,40(sp)
    80004b22:	7d02                	ld	s10,32(sp)
    80004b24:	6de2                	ld	s11,24(sp)
    80004b26:	6109                	addi	sp,sp,128
    80004b28:	8082                	ret
  for(i = 0; i < n; i++){
    80004b2a:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b2c:	21848513          	addi	a0,s1,536
    80004b30:	ffffe097          	auipc	ra,0xffffe
    80004b34:	89e080e7          	jalr	-1890(ra) # 800023ce <wakeup>
  release(&pi->lock);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	18a080e7          	jalr	394(ra) # 80000cc4 <release>
  return i;
    80004b42:	b7e1                	j	80004b0a <pipewrite+0xea>

0000000080004b44 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b44:	715d                	addi	sp,sp,-80
    80004b46:	e486                	sd	ra,72(sp)
    80004b48:	e0a2                	sd	s0,64(sp)
    80004b4a:	fc26                	sd	s1,56(sp)
    80004b4c:	f84a                	sd	s2,48(sp)
    80004b4e:	f44e                	sd	s3,40(sp)
    80004b50:	f052                	sd	s4,32(sp)
    80004b52:	ec56                	sd	s5,24(sp)
    80004b54:	e85a                	sd	s6,16(sp)
    80004b56:	0880                	addi	s0,sp,80
    80004b58:	84aa                	mv	s1,a0
    80004b5a:	892e                	mv	s2,a1
    80004b5c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	eda080e7          	jalr	-294(ra) # 80001a38 <myproc>
    80004b66:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b68:	8b26                	mv	s6,s1
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	0a4080e7          	jalr	164(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b74:	2184a703          	lw	a4,536(s1)
    80004b78:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b7c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b80:	02f71463          	bne	a4,a5,80004ba8 <piperead+0x64>
    80004b84:	2244a783          	lw	a5,548(s1)
    80004b88:	c385                	beqz	a5,80004ba8 <piperead+0x64>
    if(pr->killed){
    80004b8a:	030a2783          	lw	a5,48(s4)
    80004b8e:	ebc1                	bnez	a5,80004c1e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b90:	85da                	mv	a1,s6
    80004b92:	854e                	mv	a0,s3
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	6b4080e7          	jalr	1716(ra) # 80002248 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b9c:	2184a703          	lw	a4,536(s1)
    80004ba0:	21c4a783          	lw	a5,540(s1)
    80004ba4:	fef700e3          	beq	a4,a5,80004b84 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba8:	09505263          	blez	s5,80004c2c <piperead+0xe8>
    80004bac:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bae:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bb0:	2184a783          	lw	a5,536(s1)
    80004bb4:	21c4a703          	lw	a4,540(s1)
    80004bb8:	02f70d63          	beq	a4,a5,80004bf2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bbc:	0017871b          	addiw	a4,a5,1
    80004bc0:	20e4ac23          	sw	a4,536(s1)
    80004bc4:	1ff7f793          	andi	a5,a5,511
    80004bc8:	97a6                	add	a5,a5,s1
    80004bca:	0187c783          	lbu	a5,24(a5)
    80004bce:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bd2:	4685                	li	a3,1
    80004bd4:	fbf40613          	addi	a2,s0,-65
    80004bd8:	85ca                	mv	a1,s2
    80004bda:	050a3503          	ld	a0,80(s4)
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	b4e080e7          	jalr	-1202(ra) # 8000172c <copyout>
    80004be6:	01650663          	beq	a0,s6,80004bf2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bea:	2985                	addiw	s3,s3,1
    80004bec:	0905                	addi	s2,s2,1
    80004bee:	fd3a91e3          	bne	s5,s3,80004bb0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bf2:	21c48513          	addi	a0,s1,540
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	7d8080e7          	jalr	2008(ra) # 800023ce <wakeup>
  release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	0c4080e7          	jalr	196(ra) # 80000cc4 <release>
  return i;
}
    80004c08:	854e                	mv	a0,s3
    80004c0a:	60a6                	ld	ra,72(sp)
    80004c0c:	6406                	ld	s0,64(sp)
    80004c0e:	74e2                	ld	s1,56(sp)
    80004c10:	7942                	ld	s2,48(sp)
    80004c12:	79a2                	ld	s3,40(sp)
    80004c14:	7a02                	ld	s4,32(sp)
    80004c16:	6ae2                	ld	s5,24(sp)
    80004c18:	6b42                	ld	s6,16(sp)
    80004c1a:	6161                	addi	sp,sp,80
    80004c1c:	8082                	ret
      release(&pi->lock);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	0a4080e7          	jalr	164(ra) # 80000cc4 <release>
      return -1;
    80004c28:	59fd                	li	s3,-1
    80004c2a:	bff9                	j	80004c08 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2c:	4981                	li	s3,0
    80004c2e:	b7d1                	j	80004bf2 <piperead+0xae>

0000000080004c30 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c30:	df010113          	addi	sp,sp,-528
    80004c34:	20113423          	sd	ra,520(sp)
    80004c38:	20813023          	sd	s0,512(sp)
    80004c3c:	ffa6                	sd	s1,504(sp)
    80004c3e:	fbca                	sd	s2,496(sp)
    80004c40:	f7ce                	sd	s3,488(sp)
    80004c42:	f3d2                	sd	s4,480(sp)
    80004c44:	efd6                	sd	s5,472(sp)
    80004c46:	ebda                	sd	s6,464(sp)
    80004c48:	e7de                	sd	s7,456(sp)
    80004c4a:	e3e2                	sd	s8,448(sp)
    80004c4c:	ff66                	sd	s9,440(sp)
    80004c4e:	fb6a                	sd	s10,432(sp)
    80004c50:	f76e                	sd	s11,424(sp)
    80004c52:	0c00                	addi	s0,sp,528
    80004c54:	84aa                	mv	s1,a0
    80004c56:	dea43c23          	sd	a0,-520(s0)
    80004c5a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	dda080e7          	jalr	-550(ra) # 80001a38 <myproc>
    80004c66:	892a                	mv	s2,a0

  begin_op();
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	446080e7          	jalr	1094(ra) # 800040ae <begin_op>

  if((ip = namei(path)) == 0){
    80004c70:	8526                	mv	a0,s1
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	230080e7          	jalr	560(ra) # 80003ea2 <namei>
    80004c7a:	c92d                	beqz	a0,80004cec <exec+0xbc>
    80004c7c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	a70080e7          	jalr	-1424(ra) # 800036ee <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c86:	04000713          	li	a4,64
    80004c8a:	4681                	li	a3,0
    80004c8c:	e4840613          	addi	a2,s0,-440
    80004c90:	4581                	li	a1,0
    80004c92:	8526                	mv	a0,s1
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	d0e080e7          	jalr	-754(ra) # 800039a2 <readi>
    80004c9c:	04000793          	li	a5,64
    80004ca0:	00f51a63          	bne	a0,a5,80004cb4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ca4:	e4842703          	lw	a4,-440(s0)
    80004ca8:	464c47b7          	lui	a5,0x464c4
    80004cac:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cb0:	04f70463          	beq	a4,a5,80004cf8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	c9a080e7          	jalr	-870(ra) # 80003950 <iunlockput>
    end_op();
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	470080e7          	jalr	1136(ra) # 8000412e <end_op>
  }
  return -1;
    80004cc6:	557d                	li	a0,-1
}
    80004cc8:	20813083          	ld	ra,520(sp)
    80004ccc:	20013403          	ld	s0,512(sp)
    80004cd0:	74fe                	ld	s1,504(sp)
    80004cd2:	795e                	ld	s2,496(sp)
    80004cd4:	79be                	ld	s3,488(sp)
    80004cd6:	7a1e                	ld	s4,480(sp)
    80004cd8:	6afe                	ld	s5,472(sp)
    80004cda:	6b5e                	ld	s6,464(sp)
    80004cdc:	6bbe                	ld	s7,456(sp)
    80004cde:	6c1e                	ld	s8,448(sp)
    80004ce0:	7cfa                	ld	s9,440(sp)
    80004ce2:	7d5a                	ld	s10,432(sp)
    80004ce4:	7dba                	ld	s11,424(sp)
    80004ce6:	21010113          	addi	sp,sp,528
    80004cea:	8082                	ret
    end_op();
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	442080e7          	jalr	1090(ra) # 8000412e <end_op>
    return -1;
    80004cf4:	557d                	li	a0,-1
    80004cf6:	bfc9                	j	80004cc8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cf8:	854a                	mv	a0,s2
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	e02080e7          	jalr	-510(ra) # 80001afc <proc_pagetable>
    80004d02:	8baa                	mv	s7,a0
    80004d04:	d945                	beqz	a0,80004cb4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d06:	e6842983          	lw	s3,-408(s0)
    80004d0a:	e8045783          	lhu	a5,-384(s0)
    80004d0e:	c7ad                	beqz	a5,80004d78 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d10:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d12:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d14:	6c85                	lui	s9,0x1
    80004d16:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d1a:	def43823          	sd	a5,-528(s0)
    80004d1e:	a42d                	j	80004f48 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d20:	00004517          	auipc	a0,0x4
    80004d24:	93050513          	addi	a0,a0,-1744 # 80008650 <syscalls+0x290>
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	820080e7          	jalr	-2016(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d30:	8756                	mv	a4,s5
    80004d32:	012d86bb          	addw	a3,s11,s2
    80004d36:	4581                	li	a1,0
    80004d38:	8526                	mv	a0,s1
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	c68080e7          	jalr	-920(ra) # 800039a2 <readi>
    80004d42:	2501                	sext.w	a0,a0
    80004d44:	1aaa9963          	bne	s5,a0,80004ef6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d48:	6785                	lui	a5,0x1
    80004d4a:	0127893b          	addw	s2,a5,s2
    80004d4e:	77fd                	lui	a5,0xfffff
    80004d50:	01478a3b          	addw	s4,a5,s4
    80004d54:	1f897163          	bgeu	s2,s8,80004f36 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d58:	02091593          	slli	a1,s2,0x20
    80004d5c:	9181                	srli	a1,a1,0x20
    80004d5e:	95ea                	add	a1,a1,s10
    80004d60:	855e                	mv	a0,s7
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	428080e7          	jalr	1064(ra) # 8000118a <walkaddr>
    80004d6a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d6c:	d955                	beqz	a0,80004d20 <exec+0xf0>
      n = PGSIZE;
    80004d6e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d70:	fd9a70e3          	bgeu	s4,s9,80004d30 <exec+0x100>
      n = sz - i;
    80004d74:	8ad2                	mv	s5,s4
    80004d76:	bf6d                	j	80004d30 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d78:	4901                	li	s2,0
  iunlockput(ip);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	bd4080e7          	jalr	-1068(ra) # 80003950 <iunlockput>
  end_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	3aa080e7          	jalr	938(ra) # 8000412e <end_op>
  p = myproc();
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	cac080e7          	jalr	-852(ra) # 80001a38 <myproc>
    80004d94:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d96:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d9a:	6785                	lui	a5,0x1
    80004d9c:	17fd                	addi	a5,a5,-1
    80004d9e:	993e                	add	s2,s2,a5
    80004da0:	757d                	lui	a0,0xfffff
    80004da2:	00a977b3          	and	a5,s2,a0
    80004da6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004daa:	6609                	lui	a2,0x2
    80004dac:	963e                	add	a2,a2,a5
    80004dae:	85be                	mv	a1,a5
    80004db0:	855e                	mv	a0,s7
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	746080e7          	jalr	1862(ra) # 800014f8 <uvmalloc>
    80004dba:	8b2a                	mv	s6,a0
  ip = 0;
    80004dbc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dbe:	12050c63          	beqz	a0,80004ef6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dc2:	75f9                	lui	a1,0xffffe
    80004dc4:	95aa                	add	a1,a1,a0
    80004dc6:	855e                	mv	a0,s7
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	932080e7          	jalr	-1742(ra) # 800016fa <uvmclear>
  stackbase = sp - PGSIZE;
    80004dd0:	7c7d                	lui	s8,0xfffff
    80004dd2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dd4:	e0043783          	ld	a5,-512(s0)
    80004dd8:	6388                	ld	a0,0(a5)
    80004dda:	c535                	beqz	a0,80004e46 <exec+0x216>
    80004ddc:	e8840993          	addi	s3,s0,-376
    80004de0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004de4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	0ae080e7          	jalr	174(ra) # 80000e94 <strlen>
    80004dee:	2505                	addiw	a0,a0,1
    80004df0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004df4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004df8:	13896363          	bltu	s2,s8,80004f1e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dfc:	e0043d83          	ld	s11,-512(s0)
    80004e00:	000dba03          	ld	s4,0(s11)
    80004e04:	8552                	mv	a0,s4
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	08e080e7          	jalr	142(ra) # 80000e94 <strlen>
    80004e0e:	0015069b          	addiw	a3,a0,1
    80004e12:	8652                	mv	a2,s4
    80004e14:	85ca                	mv	a1,s2
    80004e16:	855e                	mv	a0,s7
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	914080e7          	jalr	-1772(ra) # 8000172c <copyout>
    80004e20:	10054363          	bltz	a0,80004f26 <exec+0x2f6>
    ustack[argc] = sp;
    80004e24:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e28:	0485                	addi	s1,s1,1
    80004e2a:	008d8793          	addi	a5,s11,8
    80004e2e:	e0f43023          	sd	a5,-512(s0)
    80004e32:	008db503          	ld	a0,8(s11)
    80004e36:	c911                	beqz	a0,80004e4a <exec+0x21a>
    if(argc >= MAXARG)
    80004e38:	09a1                	addi	s3,s3,8
    80004e3a:	fb3c96e3          	bne	s9,s3,80004de6 <exec+0x1b6>
  sz = sz1;
    80004e3e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e42:	4481                	li	s1,0
    80004e44:	a84d                	j	80004ef6 <exec+0x2c6>
  sp = sz;
    80004e46:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e48:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e4a:	00349793          	slli	a5,s1,0x3
    80004e4e:	f9040713          	addi	a4,s0,-112
    80004e52:	97ba                	add	a5,a5,a4
    80004e54:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e58:	00148693          	addi	a3,s1,1
    80004e5c:	068e                	slli	a3,a3,0x3
    80004e5e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e62:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e66:	01897663          	bgeu	s2,s8,80004e72 <exec+0x242>
  sz = sz1;
    80004e6a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e6e:	4481                	li	s1,0
    80004e70:	a059                	j	80004ef6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e72:	e8840613          	addi	a2,s0,-376
    80004e76:	85ca                	mv	a1,s2
    80004e78:	855e                	mv	a0,s7
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	8b2080e7          	jalr	-1870(ra) # 8000172c <copyout>
    80004e82:	0a054663          	bltz	a0,80004f2e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e86:	058ab783          	ld	a5,88(s5)
    80004e8a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e8e:	df843783          	ld	a5,-520(s0)
    80004e92:	0007c703          	lbu	a4,0(a5)
    80004e96:	cf11                	beqz	a4,80004eb2 <exec+0x282>
    80004e98:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e9a:	02f00693          	li	a3,47
    80004e9e:	a029                	j	80004ea8 <exec+0x278>
  for(last=s=path; *s; s++)
    80004ea0:	0785                	addi	a5,a5,1
    80004ea2:	fff7c703          	lbu	a4,-1(a5)
    80004ea6:	c711                	beqz	a4,80004eb2 <exec+0x282>
    if(*s == '/')
    80004ea8:	fed71ce3          	bne	a4,a3,80004ea0 <exec+0x270>
      last = s+1;
    80004eac:	def43c23          	sd	a5,-520(s0)
    80004eb0:	bfc5                	j	80004ea0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eb2:	4641                	li	a2,16
    80004eb4:	df843583          	ld	a1,-520(s0)
    80004eb8:	158a8513          	addi	a0,s5,344
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	fa6080e7          	jalr	-90(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ec4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ec8:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ecc:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ed0:	058ab783          	ld	a5,88(s5)
    80004ed4:	e6043703          	ld	a4,-416(s0)
    80004ed8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eda:	058ab783          	ld	a5,88(s5)
    80004ede:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ee2:	85ea                	mv	a1,s10
    80004ee4:	ffffd097          	auipc	ra,0xffffd
    80004ee8:	cb4080e7          	jalr	-844(ra) # 80001b98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eec:	0004851b          	sext.w	a0,s1
    80004ef0:	bbe1                	j	80004cc8 <exec+0x98>
    80004ef2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ef6:	e0843583          	ld	a1,-504(s0)
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	c9c080e7          	jalr	-868(ra) # 80001b98 <proc_freepagetable>
  if(ip){
    80004f04:	da0498e3          	bnez	s1,80004cb4 <exec+0x84>
  return -1;
    80004f08:	557d                	li	a0,-1
    80004f0a:	bb7d                	j	80004cc8 <exec+0x98>
    80004f0c:	e1243423          	sd	s2,-504(s0)
    80004f10:	b7dd                	j	80004ef6 <exec+0x2c6>
    80004f12:	e1243423          	sd	s2,-504(s0)
    80004f16:	b7c5                	j	80004ef6 <exec+0x2c6>
    80004f18:	e1243423          	sd	s2,-504(s0)
    80004f1c:	bfe9                	j	80004ef6 <exec+0x2c6>
  sz = sz1;
    80004f1e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f22:	4481                	li	s1,0
    80004f24:	bfc9                	j	80004ef6 <exec+0x2c6>
  sz = sz1;
    80004f26:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f2a:	4481                	li	s1,0
    80004f2c:	b7e9                	j	80004ef6 <exec+0x2c6>
  sz = sz1;
    80004f2e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f32:	4481                	li	s1,0
    80004f34:	b7c9                	j	80004ef6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f36:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f3a:	2b05                	addiw	s6,s6,1
    80004f3c:	0389899b          	addiw	s3,s3,56
    80004f40:	e8045783          	lhu	a5,-384(s0)
    80004f44:	e2fb5be3          	bge	s6,a5,80004d7a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f48:	2981                	sext.w	s3,s3
    80004f4a:	03800713          	li	a4,56
    80004f4e:	86ce                	mv	a3,s3
    80004f50:	e1040613          	addi	a2,s0,-496
    80004f54:	4581                	li	a1,0
    80004f56:	8526                	mv	a0,s1
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	a4a080e7          	jalr	-1462(ra) # 800039a2 <readi>
    80004f60:	03800793          	li	a5,56
    80004f64:	f8f517e3          	bne	a0,a5,80004ef2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f68:	e1042783          	lw	a5,-496(s0)
    80004f6c:	4705                	li	a4,1
    80004f6e:	fce796e3          	bne	a5,a4,80004f3a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f72:	e3843603          	ld	a2,-456(s0)
    80004f76:	e3043783          	ld	a5,-464(s0)
    80004f7a:	f8f669e3          	bltu	a2,a5,80004f0c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f7e:	e2043783          	ld	a5,-480(s0)
    80004f82:	963e                	add	a2,a2,a5
    80004f84:	f8f667e3          	bltu	a2,a5,80004f12 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f88:	85ca                	mv	a1,s2
    80004f8a:	855e                	mv	a0,s7
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	56c080e7          	jalr	1388(ra) # 800014f8 <uvmalloc>
    80004f94:	e0a43423          	sd	a0,-504(s0)
    80004f98:	d141                	beqz	a0,80004f18 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004f9a:	e2043d03          	ld	s10,-480(s0)
    80004f9e:	df043783          	ld	a5,-528(s0)
    80004fa2:	00fd77b3          	and	a5,s10,a5
    80004fa6:	fba1                	bnez	a5,80004ef6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fa8:	e1842d83          	lw	s11,-488(s0)
    80004fac:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fb0:	f80c03e3          	beqz	s8,80004f36 <exec+0x306>
    80004fb4:	8a62                	mv	s4,s8
    80004fb6:	4901                	li	s2,0
    80004fb8:	b345                	j	80004d58 <exec+0x128>

0000000080004fba <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fba:	7179                	addi	sp,sp,-48
    80004fbc:	f406                	sd	ra,40(sp)
    80004fbe:	f022                	sd	s0,32(sp)
    80004fc0:	ec26                	sd	s1,24(sp)
    80004fc2:	e84a                	sd	s2,16(sp)
    80004fc4:	1800                	addi	s0,sp,48
    80004fc6:	892e                	mv	s2,a1
    80004fc8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fca:	fdc40593          	addi	a1,s0,-36
    80004fce:	ffffe097          	auipc	ra,0xffffe
    80004fd2:	ba4080e7          	jalr	-1116(ra) # 80002b72 <argint>
    80004fd6:	04054063          	bltz	a0,80005016 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fda:	fdc42703          	lw	a4,-36(s0)
    80004fde:	47bd                	li	a5,15
    80004fe0:	02e7ed63          	bltu	a5,a4,8000501a <argfd+0x60>
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	a54080e7          	jalr	-1452(ra) # 80001a38 <myproc>
    80004fec:	fdc42703          	lw	a4,-36(s0)
    80004ff0:	01a70793          	addi	a5,a4,26
    80004ff4:	078e                	slli	a5,a5,0x3
    80004ff6:	953e                	add	a0,a0,a5
    80004ff8:	611c                	ld	a5,0(a0)
    80004ffa:	c395                	beqz	a5,8000501e <argfd+0x64>
    return -1;
  if(pfd)
    80004ffc:	00090463          	beqz	s2,80005004 <argfd+0x4a>
    *pfd = fd;
    80005000:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005004:	4501                	li	a0,0
  if(pf)
    80005006:	c091                	beqz	s1,8000500a <argfd+0x50>
    *pf = f;
    80005008:	e09c                	sd	a5,0(s1)
}
    8000500a:	70a2                	ld	ra,40(sp)
    8000500c:	7402                	ld	s0,32(sp)
    8000500e:	64e2                	ld	s1,24(sp)
    80005010:	6942                	ld	s2,16(sp)
    80005012:	6145                	addi	sp,sp,48
    80005014:	8082                	ret
    return -1;
    80005016:	557d                	li	a0,-1
    80005018:	bfcd                	j	8000500a <argfd+0x50>
    return -1;
    8000501a:	557d                	li	a0,-1
    8000501c:	b7fd                	j	8000500a <argfd+0x50>
    8000501e:	557d                	li	a0,-1
    80005020:	b7ed                	j	8000500a <argfd+0x50>

0000000080005022 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005022:	1101                	addi	sp,sp,-32
    80005024:	ec06                	sd	ra,24(sp)
    80005026:	e822                	sd	s0,16(sp)
    80005028:	e426                	sd	s1,8(sp)
    8000502a:	1000                	addi	s0,sp,32
    8000502c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	a0a080e7          	jalr	-1526(ra) # 80001a38 <myproc>
    80005036:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005038:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000503c:	4501                	li	a0,0
    8000503e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005040:	6398                	ld	a4,0(a5)
    80005042:	cb19                	beqz	a4,80005058 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005044:	2505                	addiw	a0,a0,1
    80005046:	07a1                	addi	a5,a5,8
    80005048:	fed51ce3          	bne	a0,a3,80005040 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000504c:	557d                	li	a0,-1
}
    8000504e:	60e2                	ld	ra,24(sp)
    80005050:	6442                	ld	s0,16(sp)
    80005052:	64a2                	ld	s1,8(sp)
    80005054:	6105                	addi	sp,sp,32
    80005056:	8082                	ret
      p->ofile[fd] = f;
    80005058:	01a50793          	addi	a5,a0,26
    8000505c:	078e                	slli	a5,a5,0x3
    8000505e:	963e                	add	a2,a2,a5
    80005060:	e204                	sd	s1,0(a2)
      return fd;
    80005062:	b7f5                	j	8000504e <fdalloc+0x2c>

0000000080005064 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005064:	715d                	addi	sp,sp,-80
    80005066:	e486                	sd	ra,72(sp)
    80005068:	e0a2                	sd	s0,64(sp)
    8000506a:	fc26                	sd	s1,56(sp)
    8000506c:	f84a                	sd	s2,48(sp)
    8000506e:	f44e                	sd	s3,40(sp)
    80005070:	f052                	sd	s4,32(sp)
    80005072:	ec56                	sd	s5,24(sp)
    80005074:	0880                	addi	s0,sp,80
    80005076:	89ae                	mv	s3,a1
    80005078:	8ab2                	mv	s5,a2
    8000507a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000507c:	fb040593          	addi	a1,s0,-80
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	e40080e7          	jalr	-448(ra) # 80003ec0 <nameiparent>
    80005088:	892a                	mv	s2,a0
    8000508a:	12050f63          	beqz	a0,800051c8 <create+0x164>
    return 0;

  ilock(dp);
    8000508e:	ffffe097          	auipc	ra,0xffffe
    80005092:	660080e7          	jalr	1632(ra) # 800036ee <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005096:	4601                	li	a2,0
    80005098:	fb040593          	addi	a1,s0,-80
    8000509c:	854a                	mv	a0,s2
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	b32080e7          	jalr	-1230(ra) # 80003bd0 <dirlookup>
    800050a6:	84aa                	mv	s1,a0
    800050a8:	c921                	beqz	a0,800050f8 <create+0x94>
    iunlockput(dp);
    800050aa:	854a                	mv	a0,s2
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	8a4080e7          	jalr	-1884(ra) # 80003950 <iunlockput>
    ilock(ip);
    800050b4:	8526                	mv	a0,s1
    800050b6:	ffffe097          	auipc	ra,0xffffe
    800050ba:	638080e7          	jalr	1592(ra) # 800036ee <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050be:	2981                	sext.w	s3,s3
    800050c0:	4789                	li	a5,2
    800050c2:	02f99463          	bne	s3,a5,800050ea <create+0x86>
    800050c6:	0444d783          	lhu	a5,68(s1)
    800050ca:	37f9                	addiw	a5,a5,-2
    800050cc:	17c2                	slli	a5,a5,0x30
    800050ce:	93c1                	srli	a5,a5,0x30
    800050d0:	4705                	li	a4,1
    800050d2:	00f76c63          	bltu	a4,a5,800050ea <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050d6:	8526                	mv	a0,s1
    800050d8:	60a6                	ld	ra,72(sp)
    800050da:	6406                	ld	s0,64(sp)
    800050dc:	74e2                	ld	s1,56(sp)
    800050de:	7942                	ld	s2,48(sp)
    800050e0:	79a2                	ld	s3,40(sp)
    800050e2:	7a02                	ld	s4,32(sp)
    800050e4:	6ae2                	ld	s5,24(sp)
    800050e6:	6161                	addi	sp,sp,80
    800050e8:	8082                	ret
    iunlockput(ip);
    800050ea:	8526                	mv	a0,s1
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	864080e7          	jalr	-1948(ra) # 80003950 <iunlockput>
    return 0;
    800050f4:	4481                	li	s1,0
    800050f6:	b7c5                	j	800050d6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050f8:	85ce                	mv	a1,s3
    800050fa:	00092503          	lw	a0,0(s2)
    800050fe:	ffffe097          	auipc	ra,0xffffe
    80005102:	458080e7          	jalr	1112(ra) # 80003556 <ialloc>
    80005106:	84aa                	mv	s1,a0
    80005108:	c529                	beqz	a0,80005152 <create+0xee>
  ilock(ip);
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	5e4080e7          	jalr	1508(ra) # 800036ee <ilock>
  ip->major = major;
    80005112:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005116:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000511a:	4785                	li	a5,1
    8000511c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005120:	8526                	mv	a0,s1
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	502080e7          	jalr	1282(ra) # 80003624 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000512a:	2981                	sext.w	s3,s3
    8000512c:	4785                	li	a5,1
    8000512e:	02f98a63          	beq	s3,a5,80005162 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005132:	40d0                	lw	a2,4(s1)
    80005134:	fb040593          	addi	a1,s0,-80
    80005138:	854a                	mv	a0,s2
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	ca6080e7          	jalr	-858(ra) # 80003de0 <dirlink>
    80005142:	06054b63          	bltz	a0,800051b8 <create+0x154>
  iunlockput(dp);
    80005146:	854a                	mv	a0,s2
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	808080e7          	jalr	-2040(ra) # 80003950 <iunlockput>
  return ip;
    80005150:	b759                	j	800050d6 <create+0x72>
    panic("create: ialloc");
    80005152:	00003517          	auipc	a0,0x3
    80005156:	51e50513          	addi	a0,a0,1310 # 80008670 <syscalls+0x2b0>
    8000515a:	ffffb097          	auipc	ra,0xffffb
    8000515e:	3ee080e7          	jalr	1006(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005162:	04a95783          	lhu	a5,74(s2)
    80005166:	2785                	addiw	a5,a5,1
    80005168:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000516c:	854a                	mv	a0,s2
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	4b6080e7          	jalr	1206(ra) # 80003624 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005176:	40d0                	lw	a2,4(s1)
    80005178:	00003597          	auipc	a1,0x3
    8000517c:	50858593          	addi	a1,a1,1288 # 80008680 <syscalls+0x2c0>
    80005180:	8526                	mv	a0,s1
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	c5e080e7          	jalr	-930(ra) # 80003de0 <dirlink>
    8000518a:	00054f63          	bltz	a0,800051a8 <create+0x144>
    8000518e:	00492603          	lw	a2,4(s2)
    80005192:	00003597          	auipc	a1,0x3
    80005196:	4f658593          	addi	a1,a1,1270 # 80008688 <syscalls+0x2c8>
    8000519a:	8526                	mv	a0,s1
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	c44080e7          	jalr	-956(ra) # 80003de0 <dirlink>
    800051a4:	f80557e3          	bgez	a0,80005132 <create+0xce>
      panic("create dots");
    800051a8:	00003517          	auipc	a0,0x3
    800051ac:	4e850513          	addi	a0,a0,1256 # 80008690 <syscalls+0x2d0>
    800051b0:	ffffb097          	auipc	ra,0xffffb
    800051b4:	398080e7          	jalr	920(ra) # 80000548 <panic>
    panic("create: dirlink");
    800051b8:	00003517          	auipc	a0,0x3
    800051bc:	4e850513          	addi	a0,a0,1256 # 800086a0 <syscalls+0x2e0>
    800051c0:	ffffb097          	auipc	ra,0xffffb
    800051c4:	388080e7          	jalr	904(ra) # 80000548 <panic>
    return 0;
    800051c8:	84aa                	mv	s1,a0
    800051ca:	b731                	j	800050d6 <create+0x72>

00000000800051cc <sys_dup>:
{
    800051cc:	7179                	addi	sp,sp,-48
    800051ce:	f406                	sd	ra,40(sp)
    800051d0:	f022                	sd	s0,32(sp)
    800051d2:	ec26                	sd	s1,24(sp)
    800051d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051d6:	fd840613          	addi	a2,s0,-40
    800051da:	4581                	li	a1,0
    800051dc:	4501                	li	a0,0
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	ddc080e7          	jalr	-548(ra) # 80004fba <argfd>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051e8:	02054363          	bltz	a0,8000520e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051ec:	fd843503          	ld	a0,-40(s0)
    800051f0:	00000097          	auipc	ra,0x0
    800051f4:	e32080e7          	jalr	-462(ra) # 80005022 <fdalloc>
    800051f8:	84aa                	mv	s1,a0
    return -1;
    800051fa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051fc:	00054963          	bltz	a0,8000520e <sys_dup+0x42>
  filedup(f);
    80005200:	fd843503          	ld	a0,-40(s0)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	32a080e7          	jalr	810(ra) # 8000452e <filedup>
  return fd;
    8000520c:	87a6                	mv	a5,s1
}
    8000520e:	853e                	mv	a0,a5
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	64e2                	ld	s1,24(sp)
    80005216:	6145                	addi	sp,sp,48
    80005218:	8082                	ret

000000008000521a <sys_read>:
{
    8000521a:	7179                	addi	sp,sp,-48
    8000521c:	f406                	sd	ra,40(sp)
    8000521e:	f022                	sd	s0,32(sp)
    80005220:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005222:	fe840613          	addi	a2,s0,-24
    80005226:	4581                	li	a1,0
    80005228:	4501                	li	a0,0
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	d90080e7          	jalr	-624(ra) # 80004fba <argfd>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005234:	04054163          	bltz	a0,80005276 <sys_read+0x5c>
    80005238:	fe440593          	addi	a1,s0,-28
    8000523c:	4509                	li	a0,2
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	934080e7          	jalr	-1740(ra) # 80002b72 <argint>
    return -1;
    80005246:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005248:	02054763          	bltz	a0,80005276 <sys_read+0x5c>
    8000524c:	fd840593          	addi	a1,s0,-40
    80005250:	4505                	li	a0,1
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	942080e7          	jalr	-1726(ra) # 80002b94 <argaddr>
    return -1;
    8000525a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525c:	00054d63          	bltz	a0,80005276 <sys_read+0x5c>
  return fileread(f, p, n);
    80005260:	fe442603          	lw	a2,-28(s0)
    80005264:	fd843583          	ld	a1,-40(s0)
    80005268:	fe843503          	ld	a0,-24(s0)
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	44e080e7          	jalr	1102(ra) # 800046ba <fileread>
    80005274:	87aa                	mv	a5,a0
}
    80005276:	853e                	mv	a0,a5
    80005278:	70a2                	ld	ra,40(sp)
    8000527a:	7402                	ld	s0,32(sp)
    8000527c:	6145                	addi	sp,sp,48
    8000527e:	8082                	ret

0000000080005280 <sys_write>:
{
    80005280:	7179                	addi	sp,sp,-48
    80005282:	f406                	sd	ra,40(sp)
    80005284:	f022                	sd	s0,32(sp)
    80005286:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005288:	fe840613          	addi	a2,s0,-24
    8000528c:	4581                	li	a1,0
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	d2a080e7          	jalr	-726(ra) # 80004fba <argfd>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529a:	04054163          	bltz	a0,800052dc <sys_write+0x5c>
    8000529e:	fe440593          	addi	a1,s0,-28
    800052a2:	4509                	li	a0,2
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	8ce080e7          	jalr	-1842(ra) # 80002b72 <argint>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	02054763          	bltz	a0,800052dc <sys_write+0x5c>
    800052b2:	fd840593          	addi	a1,s0,-40
    800052b6:	4505                	li	a0,1
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	8dc080e7          	jalr	-1828(ra) # 80002b94 <argaddr>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c2:	00054d63          	bltz	a0,800052dc <sys_write+0x5c>
  return filewrite(f, p, n);
    800052c6:	fe442603          	lw	a2,-28(s0)
    800052ca:	fd843583          	ld	a1,-40(s0)
    800052ce:	fe843503          	ld	a0,-24(s0)
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	4aa080e7          	jalr	1194(ra) # 8000477c <filewrite>
    800052da:	87aa                	mv	a5,a0
}
    800052dc:	853e                	mv	a0,a5
    800052de:	70a2                	ld	ra,40(sp)
    800052e0:	7402                	ld	s0,32(sp)
    800052e2:	6145                	addi	sp,sp,48
    800052e4:	8082                	ret

00000000800052e6 <sys_close>:
{
    800052e6:	1101                	addi	sp,sp,-32
    800052e8:	ec06                	sd	ra,24(sp)
    800052ea:	e822                	sd	s0,16(sp)
    800052ec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052ee:	fe040613          	addi	a2,s0,-32
    800052f2:	fec40593          	addi	a1,s0,-20
    800052f6:	4501                	li	a0,0
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	cc2080e7          	jalr	-830(ra) # 80004fba <argfd>
    return -1;
    80005300:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005302:	02054463          	bltz	a0,8000532a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	732080e7          	jalr	1842(ra) # 80001a38 <myproc>
    8000530e:	fec42783          	lw	a5,-20(s0)
    80005312:	07e9                	addi	a5,a5,26
    80005314:	078e                	slli	a5,a5,0x3
    80005316:	97aa                	add	a5,a5,a0
    80005318:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000531c:	fe043503          	ld	a0,-32(s0)
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	260080e7          	jalr	608(ra) # 80004580 <fileclose>
  return 0;
    80005328:	4781                	li	a5,0
}
    8000532a:	853e                	mv	a0,a5
    8000532c:	60e2                	ld	ra,24(sp)
    8000532e:	6442                	ld	s0,16(sp)
    80005330:	6105                	addi	sp,sp,32
    80005332:	8082                	ret

0000000080005334 <sys_fstat>:
{
    80005334:	1101                	addi	sp,sp,-32
    80005336:	ec06                	sd	ra,24(sp)
    80005338:	e822                	sd	s0,16(sp)
    8000533a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000533c:	fe840613          	addi	a2,s0,-24
    80005340:	4581                	li	a1,0
    80005342:	4501                	li	a0,0
    80005344:	00000097          	auipc	ra,0x0
    80005348:	c76080e7          	jalr	-906(ra) # 80004fba <argfd>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000534e:	02054563          	bltz	a0,80005378 <sys_fstat+0x44>
    80005352:	fe040593          	addi	a1,s0,-32
    80005356:	4505                	li	a0,1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	83c080e7          	jalr	-1988(ra) # 80002b94 <argaddr>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005362:	00054b63          	bltz	a0,80005378 <sys_fstat+0x44>
  return filestat(f, st);
    80005366:	fe043583          	ld	a1,-32(s0)
    8000536a:	fe843503          	ld	a0,-24(s0)
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	2da080e7          	jalr	730(ra) # 80004648 <filestat>
    80005376:	87aa                	mv	a5,a0
}
    80005378:	853e                	mv	a0,a5
    8000537a:	60e2                	ld	ra,24(sp)
    8000537c:	6442                	ld	s0,16(sp)
    8000537e:	6105                	addi	sp,sp,32
    80005380:	8082                	ret

0000000080005382 <sys_link>:
{
    80005382:	7169                	addi	sp,sp,-304
    80005384:	f606                	sd	ra,296(sp)
    80005386:	f222                	sd	s0,288(sp)
    80005388:	ee26                	sd	s1,280(sp)
    8000538a:	ea4a                	sd	s2,272(sp)
    8000538c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000538e:	08000613          	li	a2,128
    80005392:	ed040593          	addi	a1,s0,-304
    80005396:	4501                	li	a0,0
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	81e080e7          	jalr	-2018(ra) # 80002bb6 <argstr>
    return -1;
    800053a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a2:	10054e63          	bltz	a0,800054be <sys_link+0x13c>
    800053a6:	08000613          	li	a2,128
    800053aa:	f5040593          	addi	a1,s0,-176
    800053ae:	4505                	li	a0,1
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	806080e7          	jalr	-2042(ra) # 80002bb6 <argstr>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ba:	10054263          	bltz	a0,800054be <sys_link+0x13c>
  begin_op();
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	cf0080e7          	jalr	-784(ra) # 800040ae <begin_op>
  if((ip = namei(old)) == 0){
    800053c6:	ed040513          	addi	a0,s0,-304
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	ad8080e7          	jalr	-1320(ra) # 80003ea2 <namei>
    800053d2:	84aa                	mv	s1,a0
    800053d4:	c551                	beqz	a0,80005460 <sys_link+0xde>
  ilock(ip);
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	318080e7          	jalr	792(ra) # 800036ee <ilock>
  if(ip->type == T_DIR){
    800053de:	04449703          	lh	a4,68(s1)
    800053e2:	4785                	li	a5,1
    800053e4:	08f70463          	beq	a4,a5,8000546c <sys_link+0xea>
  ip->nlink++;
    800053e8:	04a4d783          	lhu	a5,74(s1)
    800053ec:	2785                	addiw	a5,a5,1
    800053ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	230080e7          	jalr	560(ra) # 80003624 <iupdate>
  iunlock(ip);
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	3b2080e7          	jalr	946(ra) # 800037b0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005406:	fd040593          	addi	a1,s0,-48
    8000540a:	f5040513          	addi	a0,s0,-176
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	ab2080e7          	jalr	-1358(ra) # 80003ec0 <nameiparent>
    80005416:	892a                	mv	s2,a0
    80005418:	c935                	beqz	a0,8000548c <sys_link+0x10a>
  ilock(dp);
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	2d4080e7          	jalr	724(ra) # 800036ee <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005422:	00092703          	lw	a4,0(s2)
    80005426:	409c                	lw	a5,0(s1)
    80005428:	04f71d63          	bne	a4,a5,80005482 <sys_link+0x100>
    8000542c:	40d0                	lw	a2,4(s1)
    8000542e:	fd040593          	addi	a1,s0,-48
    80005432:	854a                	mv	a0,s2
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	9ac080e7          	jalr	-1620(ra) # 80003de0 <dirlink>
    8000543c:	04054363          	bltz	a0,80005482 <sys_link+0x100>
  iunlockput(dp);
    80005440:	854a                	mv	a0,s2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	50e080e7          	jalr	1294(ra) # 80003950 <iunlockput>
  iput(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	45c080e7          	jalr	1116(ra) # 800038a8 <iput>
  end_op();
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	cda080e7          	jalr	-806(ra) # 8000412e <end_op>
  return 0;
    8000545c:	4781                	li	a5,0
    8000545e:	a085                	j	800054be <sys_link+0x13c>
    end_op();
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	cce080e7          	jalr	-818(ra) # 8000412e <end_op>
    return -1;
    80005468:	57fd                	li	a5,-1
    8000546a:	a891                	j	800054be <sys_link+0x13c>
    iunlockput(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	4e2080e7          	jalr	1250(ra) # 80003950 <iunlockput>
    end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	cb8080e7          	jalr	-840(ra) # 8000412e <end_op>
    return -1;
    8000547e:	57fd                	li	a5,-1
    80005480:	a83d                	j	800054be <sys_link+0x13c>
    iunlockput(dp);
    80005482:	854a                	mv	a0,s2
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	4cc080e7          	jalr	1228(ra) # 80003950 <iunlockput>
  ilock(ip);
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	260080e7          	jalr	608(ra) # 800036ee <ilock>
  ip->nlink--;
    80005496:	04a4d783          	lhu	a5,74(s1)
    8000549a:	37fd                	addiw	a5,a5,-1
    8000549c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	182080e7          	jalr	386(ra) # 80003624 <iupdate>
  iunlockput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	4a4080e7          	jalr	1188(ra) # 80003950 <iunlockput>
  end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	c7a080e7          	jalr	-902(ra) # 8000412e <end_op>
  return -1;
    800054bc:	57fd                	li	a5,-1
}
    800054be:	853e                	mv	a0,a5
    800054c0:	70b2                	ld	ra,296(sp)
    800054c2:	7412                	ld	s0,288(sp)
    800054c4:	64f2                	ld	s1,280(sp)
    800054c6:	6952                	ld	s2,272(sp)
    800054c8:	6155                	addi	sp,sp,304
    800054ca:	8082                	ret

00000000800054cc <sys_unlink>:
{
    800054cc:	7151                	addi	sp,sp,-240
    800054ce:	f586                	sd	ra,232(sp)
    800054d0:	f1a2                	sd	s0,224(sp)
    800054d2:	eda6                	sd	s1,216(sp)
    800054d4:	e9ca                	sd	s2,208(sp)
    800054d6:	e5ce                	sd	s3,200(sp)
    800054d8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054da:	08000613          	li	a2,128
    800054de:	f3040593          	addi	a1,s0,-208
    800054e2:	4501                	li	a0,0
    800054e4:	ffffd097          	auipc	ra,0xffffd
    800054e8:	6d2080e7          	jalr	1746(ra) # 80002bb6 <argstr>
    800054ec:	18054163          	bltz	a0,8000566e <sys_unlink+0x1a2>
  begin_op();
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	bbe080e7          	jalr	-1090(ra) # 800040ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054f8:	fb040593          	addi	a1,s0,-80
    800054fc:	f3040513          	addi	a0,s0,-208
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	9c0080e7          	jalr	-1600(ra) # 80003ec0 <nameiparent>
    80005508:	84aa                	mv	s1,a0
    8000550a:	c979                	beqz	a0,800055e0 <sys_unlink+0x114>
  ilock(dp);
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	1e2080e7          	jalr	482(ra) # 800036ee <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005514:	00003597          	auipc	a1,0x3
    80005518:	16c58593          	addi	a1,a1,364 # 80008680 <syscalls+0x2c0>
    8000551c:	fb040513          	addi	a0,s0,-80
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	696080e7          	jalr	1686(ra) # 80003bb6 <namecmp>
    80005528:	14050a63          	beqz	a0,8000567c <sys_unlink+0x1b0>
    8000552c:	00003597          	auipc	a1,0x3
    80005530:	15c58593          	addi	a1,a1,348 # 80008688 <syscalls+0x2c8>
    80005534:	fb040513          	addi	a0,s0,-80
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	67e080e7          	jalr	1662(ra) # 80003bb6 <namecmp>
    80005540:	12050e63          	beqz	a0,8000567c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005544:	f2c40613          	addi	a2,s0,-212
    80005548:	fb040593          	addi	a1,s0,-80
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	682080e7          	jalr	1666(ra) # 80003bd0 <dirlookup>
    80005556:	892a                	mv	s2,a0
    80005558:	12050263          	beqz	a0,8000567c <sys_unlink+0x1b0>
  ilock(ip);
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	192080e7          	jalr	402(ra) # 800036ee <ilock>
  if(ip->nlink < 1)
    80005564:	04a91783          	lh	a5,74(s2)
    80005568:	08f05263          	blez	a5,800055ec <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000556c:	04491703          	lh	a4,68(s2)
    80005570:	4785                	li	a5,1
    80005572:	08f70563          	beq	a4,a5,800055fc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005576:	4641                	li	a2,16
    80005578:	4581                	li	a1,0
    8000557a:	fc040513          	addi	a0,s0,-64
    8000557e:	ffffb097          	auipc	ra,0xffffb
    80005582:	78e080e7          	jalr	1934(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005586:	4741                	li	a4,16
    80005588:	f2c42683          	lw	a3,-212(s0)
    8000558c:	fc040613          	addi	a2,s0,-64
    80005590:	4581                	li	a1,0
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	506080e7          	jalr	1286(ra) # 80003a9a <writei>
    8000559c:	47c1                	li	a5,16
    8000559e:	0af51563          	bne	a0,a5,80005648 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055a2:	04491703          	lh	a4,68(s2)
    800055a6:	4785                	li	a5,1
    800055a8:	0af70863          	beq	a4,a5,80005658 <sys_unlink+0x18c>
  iunlockput(dp);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	3a2080e7          	jalr	930(ra) # 80003950 <iunlockput>
  ip->nlink--;
    800055b6:	04a95783          	lhu	a5,74(s2)
    800055ba:	37fd                	addiw	a5,a5,-1
    800055bc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055c0:	854a                	mv	a0,s2
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	062080e7          	jalr	98(ra) # 80003624 <iupdate>
  iunlockput(ip);
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	384080e7          	jalr	900(ra) # 80003950 <iunlockput>
  end_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	b5a080e7          	jalr	-1190(ra) # 8000412e <end_op>
  return 0;
    800055dc:	4501                	li	a0,0
    800055de:	a84d                	j	80005690 <sys_unlink+0x1c4>
    end_op();
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	b4e080e7          	jalr	-1202(ra) # 8000412e <end_op>
    return -1;
    800055e8:	557d                	li	a0,-1
    800055ea:	a05d                	j	80005690 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055ec:	00003517          	auipc	a0,0x3
    800055f0:	0c450513          	addi	a0,a0,196 # 800086b0 <syscalls+0x2f0>
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	f54080e7          	jalr	-172(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055fc:	04c92703          	lw	a4,76(s2)
    80005600:	02000793          	li	a5,32
    80005604:	f6e7f9e3          	bgeu	a5,a4,80005576 <sys_unlink+0xaa>
    80005608:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000560c:	4741                	li	a4,16
    8000560e:	86ce                	mv	a3,s3
    80005610:	f1840613          	addi	a2,s0,-232
    80005614:	4581                	li	a1,0
    80005616:	854a                	mv	a0,s2
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	38a080e7          	jalr	906(ra) # 800039a2 <readi>
    80005620:	47c1                	li	a5,16
    80005622:	00f51b63          	bne	a0,a5,80005638 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005626:	f1845783          	lhu	a5,-232(s0)
    8000562a:	e7a1                	bnez	a5,80005672 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000562c:	29c1                	addiw	s3,s3,16
    8000562e:	04c92783          	lw	a5,76(s2)
    80005632:	fcf9ede3          	bltu	s3,a5,8000560c <sys_unlink+0x140>
    80005636:	b781                	j	80005576 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005638:	00003517          	auipc	a0,0x3
    8000563c:	09050513          	addi	a0,a0,144 # 800086c8 <syscalls+0x308>
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	f08080e7          	jalr	-248(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005648:	00003517          	auipc	a0,0x3
    8000564c:	09850513          	addi	a0,a0,152 # 800086e0 <syscalls+0x320>
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>
    dp->nlink--;
    80005658:	04a4d783          	lhu	a5,74(s1)
    8000565c:	37fd                	addiw	a5,a5,-1
    8000565e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	fc0080e7          	jalr	-64(ra) # 80003624 <iupdate>
    8000566c:	b781                	j	800055ac <sys_unlink+0xe0>
    return -1;
    8000566e:	557d                	li	a0,-1
    80005670:	a005                	j	80005690 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	2dc080e7          	jalr	732(ra) # 80003950 <iunlockput>
  iunlockput(dp);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	2d2080e7          	jalr	722(ra) # 80003950 <iunlockput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	aa8080e7          	jalr	-1368(ra) # 8000412e <end_op>
  return -1;
    8000568e:	557d                	li	a0,-1
}
    80005690:	70ae                	ld	ra,232(sp)
    80005692:	740e                	ld	s0,224(sp)
    80005694:	64ee                	ld	s1,216(sp)
    80005696:	694e                	ld	s2,208(sp)
    80005698:	69ae                	ld	s3,200(sp)
    8000569a:	616d                	addi	sp,sp,240
    8000569c:	8082                	ret

000000008000569e <sys_open>:

uint64
sys_open(void)
{
    8000569e:	7131                	addi	sp,sp,-192
    800056a0:	fd06                	sd	ra,184(sp)
    800056a2:	f922                	sd	s0,176(sp)
    800056a4:	f526                	sd	s1,168(sp)
    800056a6:	f14a                	sd	s2,160(sp)
    800056a8:	ed4e                	sd	s3,152(sp)
    800056aa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ac:	08000613          	li	a2,128
    800056b0:	f5040593          	addi	a1,s0,-176
    800056b4:	4501                	li	a0,0
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	500080e7          	jalr	1280(ra) # 80002bb6 <argstr>
    return -1;
    800056be:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c0:	0c054163          	bltz	a0,80005782 <sys_open+0xe4>
    800056c4:	f4c40593          	addi	a1,s0,-180
    800056c8:	4505                	li	a0,1
    800056ca:	ffffd097          	auipc	ra,0xffffd
    800056ce:	4a8080e7          	jalr	1192(ra) # 80002b72 <argint>
    800056d2:	0a054863          	bltz	a0,80005782 <sys_open+0xe4>

  begin_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	9d8080e7          	jalr	-1576(ra) # 800040ae <begin_op>

  if(omode & O_CREATE){
    800056de:	f4c42783          	lw	a5,-180(s0)
    800056e2:	2007f793          	andi	a5,a5,512
    800056e6:	cbdd                	beqz	a5,8000579c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056e8:	4681                	li	a3,0
    800056ea:	4601                	li	a2,0
    800056ec:	4589                	li	a1,2
    800056ee:	f5040513          	addi	a0,s0,-176
    800056f2:	00000097          	auipc	ra,0x0
    800056f6:	972080e7          	jalr	-1678(ra) # 80005064 <create>
    800056fa:	892a                	mv	s2,a0
    if(ip == 0){
    800056fc:	c959                	beqz	a0,80005792 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056fe:	04491703          	lh	a4,68(s2)
    80005702:	478d                	li	a5,3
    80005704:	00f71763          	bne	a4,a5,80005712 <sys_open+0x74>
    80005708:	04695703          	lhu	a4,70(s2)
    8000570c:	47a5                	li	a5,9
    8000570e:	0ce7ec63          	bltu	a5,a4,800057e6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	db2080e7          	jalr	-590(ra) # 800044c4 <filealloc>
    8000571a:	89aa                	mv	s3,a0
    8000571c:	10050263          	beqz	a0,80005820 <sys_open+0x182>
    80005720:	00000097          	auipc	ra,0x0
    80005724:	902080e7          	jalr	-1790(ra) # 80005022 <fdalloc>
    80005728:	84aa                	mv	s1,a0
    8000572a:	0e054663          	bltz	a0,80005816 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	478d                	li	a5,3
    80005734:	0cf70463          	beq	a4,a5,800057fc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005738:	4789                	li	a5,2
    8000573a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000573e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005742:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005746:	f4c42783          	lw	a5,-180(s0)
    8000574a:	0017c713          	xori	a4,a5,1
    8000574e:	8b05                	andi	a4,a4,1
    80005750:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005754:	0037f713          	andi	a4,a5,3
    80005758:	00e03733          	snez	a4,a4
    8000575c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005760:	4007f793          	andi	a5,a5,1024
    80005764:	c791                	beqz	a5,80005770 <sys_open+0xd2>
    80005766:	04491703          	lh	a4,68(s2)
    8000576a:	4789                	li	a5,2
    8000576c:	08f70f63          	beq	a4,a5,8000580a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005770:	854a                	mv	a0,s2
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	03e080e7          	jalr	62(ra) # 800037b0 <iunlock>
  end_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	9b4080e7          	jalr	-1612(ra) # 8000412e <end_op>

  return fd;
}
    80005782:	8526                	mv	a0,s1
    80005784:	70ea                	ld	ra,184(sp)
    80005786:	744a                	ld	s0,176(sp)
    80005788:	74aa                	ld	s1,168(sp)
    8000578a:	790a                	ld	s2,160(sp)
    8000578c:	69ea                	ld	s3,152(sp)
    8000578e:	6129                	addi	sp,sp,192
    80005790:	8082                	ret
      end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	99c080e7          	jalr	-1636(ra) # 8000412e <end_op>
      return -1;
    8000579a:	b7e5                	j	80005782 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000579c:	f5040513          	addi	a0,s0,-176
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	702080e7          	jalr	1794(ra) # 80003ea2 <namei>
    800057a8:	892a                	mv	s2,a0
    800057aa:	c905                	beqz	a0,800057da <sys_open+0x13c>
    ilock(ip);
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	f42080e7          	jalr	-190(ra) # 800036ee <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057b4:	04491703          	lh	a4,68(s2)
    800057b8:	4785                	li	a5,1
    800057ba:	f4f712e3          	bne	a4,a5,800056fe <sys_open+0x60>
    800057be:	f4c42783          	lw	a5,-180(s0)
    800057c2:	dba1                	beqz	a5,80005712 <sys_open+0x74>
      iunlockput(ip);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	18a080e7          	jalr	394(ra) # 80003950 <iunlockput>
      end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	960080e7          	jalr	-1696(ra) # 8000412e <end_op>
      return -1;
    800057d6:	54fd                	li	s1,-1
    800057d8:	b76d                	j	80005782 <sys_open+0xe4>
      end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	954080e7          	jalr	-1708(ra) # 8000412e <end_op>
      return -1;
    800057e2:	54fd                	li	s1,-1
    800057e4:	bf79                	j	80005782 <sys_open+0xe4>
    iunlockput(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	168080e7          	jalr	360(ra) # 80003950 <iunlockput>
    end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	93e080e7          	jalr	-1730(ra) # 8000412e <end_op>
    return -1;
    800057f8:	54fd                	li	s1,-1
    800057fa:	b761                	j	80005782 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057fc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005800:	04691783          	lh	a5,70(s2)
    80005804:	02f99223          	sh	a5,36(s3)
    80005808:	bf2d                	j	80005742 <sys_open+0xa4>
    itrunc(ip);
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	ff0080e7          	jalr	-16(ra) # 800037fc <itrunc>
    80005814:	bfb1                	j	80005770 <sys_open+0xd2>
      fileclose(f);
    80005816:	854e                	mv	a0,s3
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	d68080e7          	jalr	-664(ra) # 80004580 <fileclose>
    iunlockput(ip);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	12e080e7          	jalr	302(ra) # 80003950 <iunlockput>
    end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	904080e7          	jalr	-1788(ra) # 8000412e <end_op>
    return -1;
    80005832:	54fd                	li	s1,-1
    80005834:	b7b9                	j	80005782 <sys_open+0xe4>

0000000080005836 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005836:	7175                	addi	sp,sp,-144
    80005838:	e506                	sd	ra,136(sp)
    8000583a:	e122                	sd	s0,128(sp)
    8000583c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	870080e7          	jalr	-1936(ra) # 800040ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005846:	08000613          	li	a2,128
    8000584a:	f7040593          	addi	a1,s0,-144
    8000584e:	4501                	li	a0,0
    80005850:	ffffd097          	auipc	ra,0xffffd
    80005854:	366080e7          	jalr	870(ra) # 80002bb6 <argstr>
    80005858:	02054963          	bltz	a0,8000588a <sys_mkdir+0x54>
    8000585c:	4681                	li	a3,0
    8000585e:	4601                	li	a2,0
    80005860:	4585                	li	a1,1
    80005862:	f7040513          	addi	a0,s0,-144
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	7fe080e7          	jalr	2046(ra) # 80005064 <create>
    8000586e:	cd11                	beqz	a0,8000588a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	0e0080e7          	jalr	224(ra) # 80003950 <iunlockput>
  end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	8b6080e7          	jalr	-1866(ra) # 8000412e <end_op>
  return 0;
    80005880:	4501                	li	a0,0
}
    80005882:	60aa                	ld	ra,136(sp)
    80005884:	640a                	ld	s0,128(sp)
    80005886:	6149                	addi	sp,sp,144
    80005888:	8082                	ret
    end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	8a4080e7          	jalr	-1884(ra) # 8000412e <end_op>
    return -1;
    80005892:	557d                	li	a0,-1
    80005894:	b7fd                	j	80005882 <sys_mkdir+0x4c>

0000000080005896 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005896:	7135                	addi	sp,sp,-160
    80005898:	ed06                	sd	ra,152(sp)
    8000589a:	e922                	sd	s0,144(sp)
    8000589c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	810080e7          	jalr	-2032(ra) # 800040ae <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a6:	08000613          	li	a2,128
    800058aa:	f7040593          	addi	a1,s0,-144
    800058ae:	4501                	li	a0,0
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	306080e7          	jalr	774(ra) # 80002bb6 <argstr>
    800058b8:	04054a63          	bltz	a0,8000590c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058bc:	f6c40593          	addi	a1,s0,-148
    800058c0:	4505                	li	a0,1
    800058c2:	ffffd097          	auipc	ra,0xffffd
    800058c6:	2b0080e7          	jalr	688(ra) # 80002b72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ca:	04054163          	bltz	a0,8000590c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058ce:	f6840593          	addi	a1,s0,-152
    800058d2:	4509                	li	a0,2
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	29e080e7          	jalr	670(ra) # 80002b72 <argint>
     argint(1, &major) < 0 ||
    800058dc:	02054863          	bltz	a0,8000590c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058e0:	f6841683          	lh	a3,-152(s0)
    800058e4:	f6c41603          	lh	a2,-148(s0)
    800058e8:	458d                	li	a1,3
    800058ea:	f7040513          	addi	a0,s0,-144
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	776080e7          	jalr	1910(ra) # 80005064 <create>
     argint(2, &minor) < 0 ||
    800058f6:	c919                	beqz	a0,8000590c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	058080e7          	jalr	88(ra) # 80003950 <iunlockput>
  end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	82e080e7          	jalr	-2002(ra) # 8000412e <end_op>
  return 0;
    80005908:	4501                	li	a0,0
    8000590a:	a031                	j	80005916 <sys_mknod+0x80>
    end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	822080e7          	jalr	-2014(ra) # 8000412e <end_op>
    return -1;
    80005914:	557d                	li	a0,-1
}
    80005916:	60ea                	ld	ra,152(sp)
    80005918:	644a                	ld	s0,144(sp)
    8000591a:	610d                	addi	sp,sp,160
    8000591c:	8082                	ret

000000008000591e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000591e:	7135                	addi	sp,sp,-160
    80005920:	ed06                	sd	ra,152(sp)
    80005922:	e922                	sd	s0,144(sp)
    80005924:	e526                	sd	s1,136(sp)
    80005926:	e14a                	sd	s2,128(sp)
    80005928:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000592a:	ffffc097          	auipc	ra,0xffffc
    8000592e:	10e080e7          	jalr	270(ra) # 80001a38 <myproc>
    80005932:	892a                	mv	s2,a0
  
  begin_op();
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	77a080e7          	jalr	1914(ra) # 800040ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000593c:	08000613          	li	a2,128
    80005940:	f6040593          	addi	a1,s0,-160
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	270080e7          	jalr	624(ra) # 80002bb6 <argstr>
    8000594e:	04054b63          	bltz	a0,800059a4 <sys_chdir+0x86>
    80005952:	f6040513          	addi	a0,s0,-160
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	54c080e7          	jalr	1356(ra) # 80003ea2 <namei>
    8000595e:	84aa                	mv	s1,a0
    80005960:	c131                	beqz	a0,800059a4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	d8c080e7          	jalr	-628(ra) # 800036ee <ilock>
  if(ip->type != T_DIR){
    8000596a:	04449703          	lh	a4,68(s1)
    8000596e:	4785                	li	a5,1
    80005970:	04f71063          	bne	a4,a5,800059b0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	e3a080e7          	jalr	-454(ra) # 800037b0 <iunlock>
  iput(p->cwd);
    8000597e:	15093503          	ld	a0,336(s2)
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	f26080e7          	jalr	-218(ra) # 800038a8 <iput>
  end_op();
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	7a4080e7          	jalr	1956(ra) # 8000412e <end_op>
  p->cwd = ip;
    80005992:	14993823          	sd	s1,336(s2)
  return 0;
    80005996:	4501                	li	a0,0
}
    80005998:	60ea                	ld	ra,152(sp)
    8000599a:	644a                	ld	s0,144(sp)
    8000599c:	64aa                	ld	s1,136(sp)
    8000599e:	690a                	ld	s2,128(sp)
    800059a0:	610d                	addi	sp,sp,160
    800059a2:	8082                	ret
    end_op();
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	78a080e7          	jalr	1930(ra) # 8000412e <end_op>
    return -1;
    800059ac:	557d                	li	a0,-1
    800059ae:	b7ed                	j	80005998 <sys_chdir+0x7a>
    iunlockput(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	f9e080e7          	jalr	-98(ra) # 80003950 <iunlockput>
    end_op();
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	774080e7          	jalr	1908(ra) # 8000412e <end_op>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	bfd1                	j	80005998 <sys_chdir+0x7a>

00000000800059c6 <sys_exec>:

uint64
sys_exec(void)
{
    800059c6:	7145                	addi	sp,sp,-464
    800059c8:	e786                	sd	ra,456(sp)
    800059ca:	e3a2                	sd	s0,448(sp)
    800059cc:	ff26                	sd	s1,440(sp)
    800059ce:	fb4a                	sd	s2,432(sp)
    800059d0:	f74e                	sd	s3,424(sp)
    800059d2:	f352                	sd	s4,416(sp)
    800059d4:	ef56                	sd	s5,408(sp)
    800059d6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059d8:	08000613          	li	a2,128
    800059dc:	f4040593          	addi	a1,s0,-192
    800059e0:	4501                	li	a0,0
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	1d4080e7          	jalr	468(ra) # 80002bb6 <argstr>
    return -1;
    800059ea:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ec:	0c054a63          	bltz	a0,80005ac0 <sys_exec+0xfa>
    800059f0:	e3840593          	addi	a1,s0,-456
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	19e080e7          	jalr	414(ra) # 80002b94 <argaddr>
    800059fe:	0c054163          	bltz	a0,80005ac0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a02:	10000613          	li	a2,256
    80005a06:	4581                	li	a1,0
    80005a08:	e4040513          	addi	a0,s0,-448
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	300080e7          	jalr	768(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a14:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a18:	89a6                	mv	s3,s1
    80005a1a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a1c:	02000a13          	li	s4,32
    80005a20:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a24:	00391513          	slli	a0,s2,0x3
    80005a28:	e3040593          	addi	a1,s0,-464
    80005a2c:	e3843783          	ld	a5,-456(s0)
    80005a30:	953e                	add	a0,a0,a5
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	0a6080e7          	jalr	166(ra) # 80002ad8 <fetchaddr>
    80005a3a:	02054a63          	bltz	a0,80005a6e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a3e:	e3043783          	ld	a5,-464(s0)
    80005a42:	c3b9                	beqz	a5,80005a88 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a44:	ffffb097          	auipc	ra,0xffffb
    80005a48:	0dc080e7          	jalr	220(ra) # 80000b20 <kalloc>
    80005a4c:	85aa                	mv	a1,a0
    80005a4e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a52:	cd11                	beqz	a0,80005a6e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a54:	6605                	lui	a2,0x1
    80005a56:	e3043503          	ld	a0,-464(s0)
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	0d0080e7          	jalr	208(ra) # 80002b2a <fetchstr>
    80005a62:	00054663          	bltz	a0,80005a6e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a66:	0905                	addi	s2,s2,1
    80005a68:	09a1                	addi	s3,s3,8
    80005a6a:	fb491be3          	bne	s2,s4,80005a20 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6e:	10048913          	addi	s2,s1,256
    80005a72:	6088                	ld	a0,0(s1)
    80005a74:	c529                	beqz	a0,80005abe <sys_exec+0xf8>
    kfree(argv[i]);
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	fae080e7          	jalr	-82(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a7e:	04a1                	addi	s1,s1,8
    80005a80:	ff2499e3          	bne	s1,s2,80005a72 <sys_exec+0xac>
  return -1;
    80005a84:	597d                	li	s2,-1
    80005a86:	a82d                	j	80005ac0 <sys_exec+0xfa>
      argv[i] = 0;
    80005a88:	0a8e                	slli	s5,s5,0x3
    80005a8a:	fc040793          	addi	a5,s0,-64
    80005a8e:	9abe                	add	s5,s5,a5
    80005a90:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a94:	e4040593          	addi	a1,s0,-448
    80005a98:	f4040513          	addi	a0,s0,-192
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	194080e7          	jalr	404(ra) # 80004c30 <exec>
    80005aa4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa6:	10048993          	addi	s3,s1,256
    80005aaa:	6088                	ld	a0,0(s1)
    80005aac:	c911                	beqz	a0,80005ac0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005aae:	ffffb097          	auipc	ra,0xffffb
    80005ab2:	f76080e7          	jalr	-138(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab6:	04a1                	addi	s1,s1,8
    80005ab8:	ff3499e3          	bne	s1,s3,80005aaa <sys_exec+0xe4>
    80005abc:	a011                	j	80005ac0 <sys_exec+0xfa>
  return -1;
    80005abe:	597d                	li	s2,-1
}
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	60be                	ld	ra,456(sp)
    80005ac4:	641e                	ld	s0,448(sp)
    80005ac6:	74fa                	ld	s1,440(sp)
    80005ac8:	795a                	ld	s2,432(sp)
    80005aca:	79ba                	ld	s3,424(sp)
    80005acc:	7a1a                	ld	s4,416(sp)
    80005ace:	6afa                	ld	s5,408(sp)
    80005ad0:	6179                	addi	sp,sp,464
    80005ad2:	8082                	ret

0000000080005ad4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ad4:	7139                	addi	sp,sp,-64
    80005ad6:	fc06                	sd	ra,56(sp)
    80005ad8:	f822                	sd	s0,48(sp)
    80005ada:	f426                	sd	s1,40(sp)
    80005adc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ade:	ffffc097          	auipc	ra,0xffffc
    80005ae2:	f5a080e7          	jalr	-166(ra) # 80001a38 <myproc>
    80005ae6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ae8:	fd840593          	addi	a1,s0,-40
    80005aec:	4501                	li	a0,0
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	0a6080e7          	jalr	166(ra) # 80002b94 <argaddr>
    return -1;
    80005af6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005af8:	0e054063          	bltz	a0,80005bd8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005afc:	fc840593          	addi	a1,s0,-56
    80005b00:	fd040513          	addi	a0,s0,-48
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	dd2080e7          	jalr	-558(ra) # 800048d6 <pipealloc>
    return -1;
    80005b0c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b0e:	0c054563          	bltz	a0,80005bd8 <sys_pipe+0x104>
  fd0 = -1;
    80005b12:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b16:	fd043503          	ld	a0,-48(s0)
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	508080e7          	jalr	1288(ra) # 80005022 <fdalloc>
    80005b22:	fca42223          	sw	a0,-60(s0)
    80005b26:	08054c63          	bltz	a0,80005bbe <sys_pipe+0xea>
    80005b2a:	fc843503          	ld	a0,-56(s0)
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	4f4080e7          	jalr	1268(ra) # 80005022 <fdalloc>
    80005b36:	fca42023          	sw	a0,-64(s0)
    80005b3a:	06054863          	bltz	a0,80005baa <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b3e:	4691                	li	a3,4
    80005b40:	fc440613          	addi	a2,s0,-60
    80005b44:	fd843583          	ld	a1,-40(s0)
    80005b48:	68a8                	ld	a0,80(s1)
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	be2080e7          	jalr	-1054(ra) # 8000172c <copyout>
    80005b52:	02054063          	bltz	a0,80005b72 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b56:	4691                	li	a3,4
    80005b58:	fc040613          	addi	a2,s0,-64
    80005b5c:	fd843583          	ld	a1,-40(s0)
    80005b60:	0591                	addi	a1,a1,4
    80005b62:	68a8                	ld	a0,80(s1)
    80005b64:	ffffc097          	auipc	ra,0xffffc
    80005b68:	bc8080e7          	jalr	-1080(ra) # 8000172c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b6c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6e:	06055563          	bgez	a0,80005bd8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b72:	fc442783          	lw	a5,-60(s0)
    80005b76:	07e9                	addi	a5,a5,26
    80005b78:	078e                	slli	a5,a5,0x3
    80005b7a:	97a6                	add	a5,a5,s1
    80005b7c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b80:	fc042503          	lw	a0,-64(s0)
    80005b84:	0569                	addi	a0,a0,26
    80005b86:	050e                	slli	a0,a0,0x3
    80005b88:	9526                	add	a0,a0,s1
    80005b8a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b8e:	fd043503          	ld	a0,-48(s0)
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	9ee080e7          	jalr	-1554(ra) # 80004580 <fileclose>
    fileclose(wf);
    80005b9a:	fc843503          	ld	a0,-56(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	9e2080e7          	jalr	-1566(ra) # 80004580 <fileclose>
    return -1;
    80005ba6:	57fd                	li	a5,-1
    80005ba8:	a805                	j	80005bd8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005baa:	fc442783          	lw	a5,-60(s0)
    80005bae:	0007c863          	bltz	a5,80005bbe <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bb2:	01a78513          	addi	a0,a5,26
    80005bb6:	050e                	slli	a0,a0,0x3
    80005bb8:	9526                	add	a0,a0,s1
    80005bba:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bbe:	fd043503          	ld	a0,-48(s0)
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	9be080e7          	jalr	-1602(ra) # 80004580 <fileclose>
    fileclose(wf);
    80005bca:	fc843503          	ld	a0,-56(s0)
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	9b2080e7          	jalr	-1614(ra) # 80004580 <fileclose>
    return -1;
    80005bd6:	57fd                	li	a5,-1
}
    80005bd8:	853e                	mv	a0,a5
    80005bda:	70e2                	ld	ra,56(sp)
    80005bdc:	7442                	ld	s0,48(sp)
    80005bde:	74a2                	ld	s1,40(sp)
    80005be0:	6121                	addi	sp,sp,64
    80005be2:	8082                	ret
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	d75fc0ef          	jal	ra,800029a4 <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	710c                	ld	a1,32(a0)
    80005c8c:	7510                	ld	a2,40(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	d44080e7          	jalr	-700(ra) # 80001a0c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	953e                	add	a0,a0,a5
    80005cec:	00052023          	sw	zero,0(a0)
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	d0c080e7          	jalr	-756(ra) # 80001a0c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5179b          	slliw	a5,a0,0xd
    80005d0c:	0c201537          	lui	a0,0xc201
    80005d10:	953e                	add	a0,a0,a5
  return irq;
}
    80005d12:	4148                	lw	a0,4(a0)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	ce4080e7          	jalr	-796(ra) # 80001a0c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	04a7cc63          	blt	a5,a0,80005da8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d54:	0001d797          	auipc	a5,0x1d
    80005d58:	2ac78793          	addi	a5,a5,684 # 80023000 <disk>
    80005d5c:	00a78733          	add	a4,a5,a0
    80005d60:	6789                	lui	a5,0x2
    80005d62:	97ba                	add	a5,a5,a4
    80005d64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d68:	eba1                	bnez	a5,80005db8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d6a:	00451713          	slli	a4,a0,0x4
    80005d6e:	0001f797          	auipc	a5,0x1f
    80005d72:	2927b783          	ld	a5,658(a5) # 80025000 <disk+0x2000>
    80005d76:	97ba                	add	a5,a5,a4
    80005d78:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d7c:	0001d797          	auipc	a5,0x1d
    80005d80:	28478793          	addi	a5,a5,644 # 80023000 <disk>
    80005d84:	97aa                	add	a5,a5,a0
    80005d86:	6509                	lui	a0,0x2
    80005d88:	953e                	add	a0,a0,a5
    80005d8a:	4785                	li	a5,1
    80005d8c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d90:	0001f517          	auipc	a0,0x1f
    80005d94:	28850513          	addi	a0,a0,648 # 80025018 <disk+0x2018>
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	636080e7          	jalr	1590(ra) # 800023ce <wakeup>
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005da8:	00003517          	auipc	a0,0x3
    80005dac:	94850513          	addi	a0,a0,-1720 # 800086f0 <syscalls+0x330>
    80005db0:	ffffa097          	auipc	ra,0xffffa
    80005db4:	798080e7          	jalr	1944(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005db8:	00003517          	auipc	a0,0x3
    80005dbc:	95050513          	addi	a0,a0,-1712 # 80008708 <syscalls+0x348>
    80005dc0:	ffffa097          	auipc	ra,0xffffa
    80005dc4:	788080e7          	jalr	1928(ra) # 80000548 <panic>

0000000080005dc8 <virtio_disk_init>:
{
    80005dc8:	1101                	addi	sp,sp,-32
    80005dca:	ec06                	sd	ra,24(sp)
    80005dcc:	e822                	sd	s0,16(sp)
    80005dce:	e426                	sd	s1,8(sp)
    80005dd0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dd2:	00003597          	auipc	a1,0x3
    80005dd6:	94e58593          	addi	a1,a1,-1714 # 80008720 <syscalls+0x360>
    80005dda:	0001f517          	auipc	a0,0x1f
    80005dde:	2ce50513          	addi	a0,a0,718 # 800250a8 <disk+0x20a8>
    80005de2:	ffffb097          	auipc	ra,0xffffb
    80005de6:	d9e080e7          	jalr	-610(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dea:	100017b7          	lui	a5,0x10001
    80005dee:	4398                	lw	a4,0(a5)
    80005df0:	2701                	sext.w	a4,a4
    80005df2:	747277b7          	lui	a5,0x74727
    80005df6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dfa:	0ef71163          	bne	a4,a5,80005edc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dfe:	100017b7          	lui	a5,0x10001
    80005e02:	43dc                	lw	a5,4(a5)
    80005e04:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e06:	4705                	li	a4,1
    80005e08:	0ce79a63          	bne	a5,a4,80005edc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	479c                	lw	a5,8(a5)
    80005e12:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e14:	4709                	li	a4,2
    80005e16:	0ce79363          	bne	a5,a4,80005edc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e1a:	100017b7          	lui	a5,0x10001
    80005e1e:	47d8                	lw	a4,12(a5)
    80005e20:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e22:	554d47b7          	lui	a5,0x554d4
    80005e26:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e2a:	0af71963          	bne	a4,a5,80005edc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	4705                	li	a4,1
    80005e34:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e36:	470d                	li	a4,3
    80005e38:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e3a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e3c:	c7ffe737          	lui	a4,0xc7ffe
    80005e40:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e44:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e46:	2701                	sext.w	a4,a4
    80005e48:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4a:	472d                	li	a4,11
    80005e4c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	473d                	li	a4,15
    80005e50:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e52:	6705                	lui	a4,0x1
    80005e54:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e56:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e5a:	5bdc                	lw	a5,52(a5)
    80005e5c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e5e:	c7d9                	beqz	a5,80005eec <virtio_disk_init+0x124>
  if(max < NUM)
    80005e60:	471d                	li	a4,7
    80005e62:	08f77d63          	bgeu	a4,a5,80005efc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e66:	100014b7          	lui	s1,0x10001
    80005e6a:	47a1                	li	a5,8
    80005e6c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e6e:	6609                	lui	a2,0x2
    80005e70:	4581                	li	a1,0
    80005e72:	0001d517          	auipc	a0,0x1d
    80005e76:	18e50513          	addi	a0,a0,398 # 80023000 <disk>
    80005e7a:	ffffb097          	auipc	ra,0xffffb
    80005e7e:	e92080e7          	jalr	-366(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e82:	0001d717          	auipc	a4,0x1d
    80005e86:	17e70713          	addi	a4,a4,382 # 80023000 <disk>
    80005e8a:	00c75793          	srli	a5,a4,0xc
    80005e8e:	2781                	sext.w	a5,a5
    80005e90:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e92:	0001f797          	auipc	a5,0x1f
    80005e96:	16e78793          	addi	a5,a5,366 # 80025000 <disk+0x2000>
    80005e9a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e9c:	0001d717          	auipc	a4,0x1d
    80005ea0:	1e470713          	addi	a4,a4,484 # 80023080 <disk+0x80>
    80005ea4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ea6:	0001e717          	auipc	a4,0x1e
    80005eaa:	15a70713          	addi	a4,a4,346 # 80024000 <disk+0x1000>
    80005eae:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eb0:	4705                	li	a4,1
    80005eb2:	00e78c23          	sb	a4,24(a5)
    80005eb6:	00e78ca3          	sb	a4,25(a5)
    80005eba:	00e78d23          	sb	a4,26(a5)
    80005ebe:	00e78da3          	sb	a4,27(a5)
    80005ec2:	00e78e23          	sb	a4,28(a5)
    80005ec6:	00e78ea3          	sb	a4,29(a5)
    80005eca:	00e78f23          	sb	a4,30(a5)
    80005ece:	00e78fa3          	sb	a4,31(a5)
}
    80005ed2:	60e2                	ld	ra,24(sp)
    80005ed4:	6442                	ld	s0,16(sp)
    80005ed6:	64a2                	ld	s1,8(sp)
    80005ed8:	6105                	addi	sp,sp,32
    80005eda:	8082                	ret
    panic("could not find virtio disk");
    80005edc:	00003517          	auipc	a0,0x3
    80005ee0:	85450513          	addi	a0,a0,-1964 # 80008730 <syscalls+0x370>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	664080e7          	jalr	1636(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005eec:	00003517          	auipc	a0,0x3
    80005ef0:	86450513          	addi	a0,a0,-1948 # 80008750 <syscalls+0x390>
    80005ef4:	ffffa097          	auipc	ra,0xffffa
    80005ef8:	654080e7          	jalr	1620(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005efc:	00003517          	auipc	a0,0x3
    80005f00:	87450513          	addi	a0,a0,-1932 # 80008770 <syscalls+0x3b0>
    80005f04:	ffffa097          	auipc	ra,0xffffa
    80005f08:	644080e7          	jalr	1604(ra) # 80000548 <panic>

0000000080005f0c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f0c:	7119                	addi	sp,sp,-128
    80005f0e:	fc86                	sd	ra,120(sp)
    80005f10:	f8a2                	sd	s0,112(sp)
    80005f12:	f4a6                	sd	s1,104(sp)
    80005f14:	f0ca                	sd	s2,96(sp)
    80005f16:	ecce                	sd	s3,88(sp)
    80005f18:	e8d2                	sd	s4,80(sp)
    80005f1a:	e4d6                	sd	s5,72(sp)
    80005f1c:	e0da                	sd	s6,64(sp)
    80005f1e:	fc5e                	sd	s7,56(sp)
    80005f20:	f862                	sd	s8,48(sp)
    80005f22:	f466                	sd	s9,40(sp)
    80005f24:	f06a                	sd	s10,32(sp)
    80005f26:	0100                	addi	s0,sp,128
    80005f28:	892a                	mv	s2,a0
    80005f2a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f2c:	00c52c83          	lw	s9,12(a0)
    80005f30:	001c9c9b          	slliw	s9,s9,0x1
    80005f34:	1c82                	slli	s9,s9,0x20
    80005f36:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f3a:	0001f517          	auipc	a0,0x1f
    80005f3e:	16e50513          	addi	a0,a0,366 # 800250a8 <disk+0x20a8>
    80005f42:	ffffb097          	auipc	ra,0xffffb
    80005f46:	cce080e7          	jalr	-818(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005f4a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f4c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f4e:	0001db97          	auipc	s7,0x1d
    80005f52:	0b2b8b93          	addi	s7,s7,178 # 80023000 <disk>
    80005f56:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f58:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f5a:	8a4e                	mv	s4,s3
    80005f5c:	a051                	j	80005fe0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f5e:	00fb86b3          	add	a3,s7,a5
    80005f62:	96da                	add	a3,a3,s6
    80005f64:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f68:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f6a:	0207c563          	bltz	a5,80005f94 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f6e:	2485                	addiw	s1,s1,1
    80005f70:	0711                	addi	a4,a4,4
    80005f72:	23548d63          	beq	s1,s5,800061ac <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005f76:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f78:	0001f697          	auipc	a3,0x1f
    80005f7c:	0a068693          	addi	a3,a3,160 # 80025018 <disk+0x2018>
    80005f80:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f82:	0006c583          	lbu	a1,0(a3)
    80005f86:	fde1                	bnez	a1,80005f5e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f88:	2785                	addiw	a5,a5,1
    80005f8a:	0685                	addi	a3,a3,1
    80005f8c:	ff879be3          	bne	a5,s8,80005f82 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f90:	57fd                	li	a5,-1
    80005f92:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f94:	02905a63          	blez	s1,80005fc8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f98:	f9042503          	lw	a0,-112(s0)
    80005f9c:	00000097          	auipc	ra,0x0
    80005fa0:	daa080e7          	jalr	-598(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fa4:	4785                	li	a5,1
    80005fa6:	0297d163          	bge	a5,s1,80005fc8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005faa:	f9442503          	lw	a0,-108(s0)
    80005fae:	00000097          	auipc	ra,0x0
    80005fb2:	d98080e7          	jalr	-616(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fb6:	4789                	li	a5,2
    80005fb8:	0097d863          	bge	a5,s1,80005fc8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fbc:	f9842503          	lw	a0,-104(s0)
    80005fc0:	00000097          	auipc	ra,0x0
    80005fc4:	d86080e7          	jalr	-634(ra) # 80005d46 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fc8:	0001f597          	auipc	a1,0x1f
    80005fcc:	0e058593          	addi	a1,a1,224 # 800250a8 <disk+0x20a8>
    80005fd0:	0001f517          	auipc	a0,0x1f
    80005fd4:	04850513          	addi	a0,a0,72 # 80025018 <disk+0x2018>
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	270080e7          	jalr	624(ra) # 80002248 <sleep>
  for(int i = 0; i < 3; i++){
    80005fe0:	f9040713          	addi	a4,s0,-112
    80005fe4:	84ce                	mv	s1,s3
    80005fe6:	bf41                	j	80005f76 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80005fe8:	4785                	li	a5,1
    80005fea:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    80005fee:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005ff2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005ff6:	f9042983          	lw	s3,-112(s0)
    80005ffa:	00499493          	slli	s1,s3,0x4
    80005ffe:	0001fa17          	auipc	s4,0x1f
    80006002:	002a0a13          	addi	s4,s4,2 # 80025000 <disk+0x2000>
    80006006:	000a3a83          	ld	s5,0(s4)
    8000600a:	9aa6                	add	s5,s5,s1
    8000600c:	f8040513          	addi	a0,s0,-128
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	08e080e7          	jalr	142(ra) # 8000109e <kvmpa>
    80006018:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000601c:	000a3783          	ld	a5,0(s4)
    80006020:	97a6                	add	a5,a5,s1
    80006022:	4741                	li	a4,16
    80006024:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006026:	000a3783          	ld	a5,0(s4)
    8000602a:	97a6                	add	a5,a5,s1
    8000602c:	4705                	li	a4,1
    8000602e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006032:	f9442703          	lw	a4,-108(s0)
    80006036:	000a3783          	ld	a5,0(s4)
    8000603a:	97a6                	add	a5,a5,s1
    8000603c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006040:	0712                	slli	a4,a4,0x4
    80006042:	000a3783          	ld	a5,0(s4)
    80006046:	97ba                	add	a5,a5,a4
    80006048:	05890693          	addi	a3,s2,88
    8000604c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000604e:	000a3783          	ld	a5,0(s4)
    80006052:	97ba                	add	a5,a5,a4
    80006054:	40000693          	li	a3,1024
    80006058:	c794                	sw	a3,8(a5)
  if(write)
    8000605a:	100d0a63          	beqz	s10,8000616e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000605e:	0001f797          	auipc	a5,0x1f
    80006062:	fa27b783          	ld	a5,-94(a5) # 80025000 <disk+0x2000>
    80006066:	97ba                	add	a5,a5,a4
    80006068:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000606c:	0001d517          	auipc	a0,0x1d
    80006070:	f9450513          	addi	a0,a0,-108 # 80023000 <disk>
    80006074:	0001f797          	auipc	a5,0x1f
    80006078:	f8c78793          	addi	a5,a5,-116 # 80025000 <disk+0x2000>
    8000607c:	6394                	ld	a3,0(a5)
    8000607e:	96ba                	add	a3,a3,a4
    80006080:	00c6d603          	lhu	a2,12(a3)
    80006084:	00166613          	ori	a2,a2,1
    80006088:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000608c:	f9842683          	lw	a3,-104(s0)
    80006090:	6390                	ld	a2,0(a5)
    80006092:	9732                	add	a4,a4,a2
    80006094:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006098:	20098613          	addi	a2,s3,512
    8000609c:	0612                	slli	a2,a2,0x4
    8000609e:	962a                	add	a2,a2,a0
    800060a0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060a4:	00469713          	slli	a4,a3,0x4
    800060a8:	6394                	ld	a3,0(a5)
    800060aa:	96ba                	add	a3,a3,a4
    800060ac:	6589                	lui	a1,0x2
    800060ae:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060b2:	94ae                	add	s1,s1,a1
    800060b4:	94aa                	add	s1,s1,a0
    800060b6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060b8:	6394                	ld	a3,0(a5)
    800060ba:	96ba                	add	a3,a3,a4
    800060bc:	4585                	li	a1,1
    800060be:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060c0:	6394                	ld	a3,0(a5)
    800060c2:	96ba                	add	a3,a3,a4
    800060c4:	4509                	li	a0,2
    800060c6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060ca:	6394                	ld	a3,0(a5)
    800060cc:	9736                	add	a4,a4,a3
    800060ce:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060d2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800060d6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800060da:	6794                	ld	a3,8(a5)
    800060dc:	0026d703          	lhu	a4,2(a3)
    800060e0:	8b1d                	andi	a4,a4,7
    800060e2:	2709                	addiw	a4,a4,2
    800060e4:	0706                	slli	a4,a4,0x1
    800060e6:	9736                	add	a4,a4,a3
    800060e8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800060ec:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800060f0:	6798                	ld	a4,8(a5)
    800060f2:	00275783          	lhu	a5,2(a4)
    800060f6:	2785                	addiw	a5,a5,1
    800060f8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060fc:	100017b7          	lui	a5,0x10001
    80006100:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006104:	00492703          	lw	a4,4(s2)
    80006108:	4785                	li	a5,1
    8000610a:	02f71163          	bne	a4,a5,8000612c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000610e:	0001f997          	auipc	s3,0x1f
    80006112:	f9a98993          	addi	s3,s3,-102 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006116:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006118:	85ce                	mv	a1,s3
    8000611a:	854a                	mv	a0,s2
    8000611c:	ffffc097          	auipc	ra,0xffffc
    80006120:	12c080e7          	jalr	300(ra) # 80002248 <sleep>
  while(b->disk == 1) {
    80006124:	00492783          	lw	a5,4(s2)
    80006128:	fe9788e3          	beq	a5,s1,80006118 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000612c:	f9042483          	lw	s1,-112(s0)
    80006130:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006134:	00479713          	slli	a4,a5,0x4
    80006138:	0001d797          	auipc	a5,0x1d
    8000613c:	ec878793          	addi	a5,a5,-312 # 80023000 <disk>
    80006140:	97ba                	add	a5,a5,a4
    80006142:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006146:	0001f917          	auipc	s2,0x1f
    8000614a:	eba90913          	addi	s2,s2,-326 # 80025000 <disk+0x2000>
    free_desc(i);
    8000614e:	8526                	mv	a0,s1
    80006150:	00000097          	auipc	ra,0x0
    80006154:	bf6080e7          	jalr	-1034(ra) # 80005d46 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006158:	0492                	slli	s1,s1,0x4
    8000615a:	00093783          	ld	a5,0(s2)
    8000615e:	94be                	add	s1,s1,a5
    80006160:	00c4d783          	lhu	a5,12(s1)
    80006164:	8b85                	andi	a5,a5,1
    80006166:	cf89                	beqz	a5,80006180 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006168:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000616c:	b7cd                	j	8000614e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000616e:	0001f797          	auipc	a5,0x1f
    80006172:	e927b783          	ld	a5,-366(a5) # 80025000 <disk+0x2000>
    80006176:	97ba                	add	a5,a5,a4
    80006178:	4689                	li	a3,2
    8000617a:	00d79623          	sh	a3,12(a5)
    8000617e:	b5fd                	j	8000606c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006180:	0001f517          	auipc	a0,0x1f
    80006184:	f2850513          	addi	a0,a0,-216 # 800250a8 <disk+0x20a8>
    80006188:	ffffb097          	auipc	ra,0xffffb
    8000618c:	b3c080e7          	jalr	-1220(ra) # 80000cc4 <release>
}
    80006190:	70e6                	ld	ra,120(sp)
    80006192:	7446                	ld	s0,112(sp)
    80006194:	74a6                	ld	s1,104(sp)
    80006196:	7906                	ld	s2,96(sp)
    80006198:	69e6                	ld	s3,88(sp)
    8000619a:	6a46                	ld	s4,80(sp)
    8000619c:	6aa6                	ld	s5,72(sp)
    8000619e:	6b06                	ld	s6,64(sp)
    800061a0:	7be2                	ld	s7,56(sp)
    800061a2:	7c42                	ld	s8,48(sp)
    800061a4:	7ca2                	ld	s9,40(sp)
    800061a6:	7d02                	ld	s10,32(sp)
    800061a8:	6109                	addi	sp,sp,128
    800061aa:	8082                	ret
  if(write)
    800061ac:	e20d1ee3          	bnez	s10,80005fe8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061b0:	f8042023          	sw	zero,-128(s0)
    800061b4:	bd2d                	j	80005fee <virtio_disk_rw+0xe2>

00000000800061b6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061b6:	1101                	addi	sp,sp,-32
    800061b8:	ec06                	sd	ra,24(sp)
    800061ba:	e822                	sd	s0,16(sp)
    800061bc:	e426                	sd	s1,8(sp)
    800061be:	e04a                	sd	s2,0(sp)
    800061c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061c2:	0001f517          	auipc	a0,0x1f
    800061c6:	ee650513          	addi	a0,a0,-282 # 800250a8 <disk+0x20a8>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	a46080e7          	jalr	-1466(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061d2:	0001f717          	auipc	a4,0x1f
    800061d6:	e2e70713          	addi	a4,a4,-466 # 80025000 <disk+0x2000>
    800061da:	02075783          	lhu	a5,32(a4)
    800061de:	6b18                	ld	a4,16(a4)
    800061e0:	00275683          	lhu	a3,2(a4)
    800061e4:	8ebd                	xor	a3,a3,a5
    800061e6:	8a9d                	andi	a3,a3,7
    800061e8:	cab9                	beqz	a3,8000623e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800061ea:	0001d917          	auipc	s2,0x1d
    800061ee:	e1690913          	addi	s2,s2,-490 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061f2:	0001f497          	auipc	s1,0x1f
    800061f6:	e0e48493          	addi	s1,s1,-498 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061fa:	078e                	slli	a5,a5,0x3
    800061fc:	97ba                	add	a5,a5,a4
    800061fe:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006200:	20078713          	addi	a4,a5,512
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	974a                	add	a4,a4,s2
    80006208:	03074703          	lbu	a4,48(a4)
    8000620c:	ef21                	bnez	a4,80006264 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000620e:	20078793          	addi	a5,a5,512
    80006212:	0792                	slli	a5,a5,0x4
    80006214:	97ca                	add	a5,a5,s2
    80006216:	7798                	ld	a4,40(a5)
    80006218:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000621c:	7788                	ld	a0,40(a5)
    8000621e:	ffffc097          	auipc	ra,0xffffc
    80006222:	1b0080e7          	jalr	432(ra) # 800023ce <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006226:	0204d783          	lhu	a5,32(s1)
    8000622a:	2785                	addiw	a5,a5,1
    8000622c:	8b9d                	andi	a5,a5,7
    8000622e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	6898                	ld	a4,16(s1)
    80006234:	00275683          	lhu	a3,2(a4)
    80006238:	8a9d                	andi	a3,a3,7
    8000623a:	fcf690e3          	bne	a3,a5,800061fa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000623e:	10001737          	lui	a4,0x10001
    80006242:	533c                	lw	a5,96(a4)
    80006244:	8b8d                	andi	a5,a5,3
    80006246:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006248:	0001f517          	auipc	a0,0x1f
    8000624c:	e6050513          	addi	a0,a0,-416 # 800250a8 <disk+0x20a8>
    80006250:	ffffb097          	auipc	ra,0xffffb
    80006254:	a74080e7          	jalr	-1420(ra) # 80000cc4 <release>
}
    80006258:	60e2                	ld	ra,24(sp)
    8000625a:	6442                	ld	s0,16(sp)
    8000625c:	64a2                	ld	s1,8(sp)
    8000625e:	6902                	ld	s2,0(sp)
    80006260:	6105                	addi	sp,sp,32
    80006262:	8082                	ret
      panic("virtio_disk_intr status");
    80006264:	00002517          	auipc	a0,0x2
    80006268:	52c50513          	addi	a0,a0,1324 # 80008790 <syscalls+0x3d0>
    8000626c:	ffffa097          	auipc	ra,0xffffa
    80006270:	2dc080e7          	jalr	732(ra) # 80000548 <panic>
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
