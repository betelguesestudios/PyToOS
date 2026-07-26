volatile unsigned char* video_memory = (volatile unsigned char*)0xB8000;
int cursor_x = 0;
int cursor_y = 0;
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;
void outb(unsigned short port, unsigned char value) {
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}
void update_cursor_position() {
    unsigned short position = cursor_y * VGA_WIDTH + cursor_x;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(position & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)((position >> 8) & 0xFF));
}

void clear_screen() {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT * 2; i += 2) {
        video_memory[i] = ' ';  
        video_memory[i+1] = 0x07; 
    }
    cursor_x = 0;
    cursor_y = 0;
    update_cursor_position();
}

void newline() {
    cursor_x = 0;
    cursor_y++;
    if (cursor_y >= VGA_HEIGHT) {
        for (int y = 0; y < VGA_HEIGHT - 1; y++) {
            for (int x = 0; x < VGA_WIDTH; x++) {
                int source = (y + 1) * VGA_WIDTH * 2 + x * 2;
                int dest = y * VGA_WIDTH * 2 + x * 2;
                video_memory[dest] = video_memory[source];
                video_memory[dest + 1] = video_memory[source + 1];
            }
        }
        for (int x = 0; x < VGA_WIDTH; x++) {
            int offset = (VGA_HEIGHT - 1) * VGA_WIDTH * 2 + x * 2;
            video_memory[offset] = ' ';
            video_memory[offset + 1] = 0x07;
        }
        cursor_y = VGA_HEIGHT - 1;
    }
    
    update_cursor_position();
}

void print_char(char c) {
    if (c == '\n') {
        newline();
        return;
    }
    
    int offset = (cursor_y * VGA_WIDTH + cursor_x) * 2;
    video_memory[offset] = c;
    video_memory[offset + 1] = 0x0F; 
    
    cursor_x++;
    if (cursor_x >= VGA_WIDTH) {
        newline();
    }
    
    update_cursor_position();
}

void print_string(const char* str) {
    int i = 0;
    
    while (str[i] != '\0') {
        print_char(str[i]);
        i++;
    }
}

void kernel_main() {
    clear_screen();
    print_string("i got on at 2:00 btw\n");
    print_string("very fun\n");
    print_string("yo how did this not break yet\n");
    print_string("new line test!");
    while(1); 
}