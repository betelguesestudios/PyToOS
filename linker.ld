ENTRY(start)

SECTIONS
{
   . = 0x100000;

   .multiboot : {
       *(.multiboot)
       *(.text)
   }

   .rodata : {
       *(.rodata)
   }

   .data : {
       *(.data)
   }

   .bss : {
       *(.bss)
   }
}
