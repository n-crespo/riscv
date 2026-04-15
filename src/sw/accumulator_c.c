/**
 * Vector sum implementation in C for risc-v comparison
 */
void main() {
  // map pointers to your specific memory addresses
  volatile int* ptr = (int*)1024;
  volatile int* result_out = (int*)16;

  int sum = 0;
  int count = 5;

  // manually prep memory like your asm does
  ptr[0] = 10;
  ptr[1] = 20;
  ptr[2] = 30;
  ptr[3] = 40;
  ptr[4] = 50;

  // the accumulation loop
  for (int i = 0; i < count; i++) {
    sum += ptr[i];
  }

  // store the final result
  *result_out = sum;

  // sentinel for your testbench
  __asm__ volatile("ebreak");
}
