ENTRY(start)

SECTIONS
{
    . = 0x7E00;  /* Load right after bootloader */

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}