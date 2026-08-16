// PyToC generated file 
 
// Including preq: display.preq 
void int_to_string(int value, char* buffer);
void print_int(int value);
volatile unsigned char* video_memory = (volatile unsigned char*)0xB8000;
int cursor_x = 0;
int cursor_y = 0;
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;
unsigned char current_color = 0x0F;

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
        video_memory[i+1] = current_color;
    }
    cursor_x = 0;
    cursor_y = 0;
    update_cursor_position();
}

void scroll() {
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
        video_memory[offset + 1] = current_color;
    }
    cursor_y = VGA_HEIGHT - 1;
    cursor_x = 0;
    update_cursor_position();
}

void newline() {
    cursor_x = 0;
    cursor_y++;
    if (cursor_y >= VGA_HEIGHT) {
        scroll();
    } else {
        update_cursor_position();
    }
}

void print_char(char c) {
    if (c == '\n') {
        newline();
        return;
    }
    
    if (c == '\b') {
        if (cursor_x > 0) {
            cursor_x--;
            int offset = (cursor_y * VGA_WIDTH + cursor_x) * 2;
            video_memory[offset] = ' ';
            video_memory[offset + 1] = current_color;
            update_cursor_position();
        } else if (cursor_y > 0) {
            cursor_y--;
            cursor_x = VGA_WIDTH - 1;
            int offset = (cursor_y * VGA_WIDTH + cursor_x) * 2;
            video_memory[offset] = ' ';
            video_memory[offset + 1] = current_color;
            update_cursor_position();
        }
        return;
    }
    
    if (c == '\t') {
        int spaces = 8 - (cursor_x % 8);
        for (int i = 0; i < spaces; i++) {
            print_char(' ');
        }
        return;
    }
    
    if (c == '\r') {
        cursor_x = 0;
        update_cursor_position();
        return;
    }
    
    int offset = (cursor_y * VGA_WIDTH + cursor_x) * 2;
    video_memory[offset] = c;
    video_memory[offset + 1] = current_color;
    
    cursor_x++;
    if (cursor_x >= VGA_WIDTH) {
        newline();
    } else {
        update_cursor_position();
    }
}

void print_string(const char* str) {
    int i = 0;
    while (str[i] != '\0') {
        print_char(str[i]);
        i++;
    }
}

void set_text_color(unsigned char foreground, unsigned char background) {
    current_color = (background << 4) | (foreground & 0x0F);
}

unsigned char parse_int(const char* str) {
    unsigned char value = 0;
    while (*str == ' ' || *str == '\t') str++;
    while (*str >= '0' && *str <= '9') {
        value = value * 10 + (unsigned char)(*str - '0');
        str++;
    }
    return value;
}

void set_foreground(unsigned char color) {
    current_color = (current_color & 0xF0) | (color & 0x0F);
}

void set_background(unsigned char color) {
    current_color = (current_color & 0x0F) | ((color & 0x0F) << 4);
}

void print_int(int value) {
    char buffer[32];
    int_to_string(value, buffer);
    print_string(buffer);
}

void int_to_string(int value, char* buffer) {
    if (value == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }

    int is_negative = 0;
    if (value < 0) {
        is_negative = 1;
        value = -value;
    }

    char temp[32];
    int i = 0;
    while (value > 0) {
        temp[i++] = '0' + (value % 10);
        value /= 10;
    }

    int j = 0;
    if (is_negative) {
        buffer[j++] = '-';
    }
    for (int k = i - 1; k >= 0; k--) {
        buffer[j++] = temp[k];
    }
    buffer[j] = '\0';
}

void print_float(float value) {
    print_int((int)value);
} 
// Including preq: color.preq 
unsigned char parse_int(const char* str);
unsigned char parse_color(const char* str) {
    const char* s = str;
    while (*s == ' ' || *s == '\t' || *s == '"' || *s == '\'') s++;
    if (*s >= '0' && *s <= '9') return parse_int(s);
    char token[16];
    int i = 0;
    while (((*s >= 'A' && *s <= 'Z') || (*s >= 'a' && *s <= 'z') || (*s >= '0' && *s <= '9') || *s == '_') && i < 15) {
        token[i++] = *s;
        s++;
    }
    token[i] = '\0';
    for (int j = 0; j < i; j++) {
        if (token[j] >= 'A' && token[j] <= 'Z') token[j] += 32;
    }
    if (i == 0) return 7;
    int streq(const char*, const char*);
    if (streq(token, "black")) return 0;
    if (streq(token, "blue")) return 1;
    if (streq(token, "green")) return 2;
    if (streq(token, "cyan")) return 3;
    if (streq(token, "red")) return 4;
    if (streq(token, "magenta")) return 5;
    if (streq(token, "brown") || streq(token, "yellow")) return 6;
    if (streq(token, "light_gray") || streq(token, "lightgrey") || streq(token, "lightgray") || streq(token, "grey") || streq(token, "gray")) return 7;
    if (streq(token, "dark_gray") || streq(token, "darkgrey")) return 8;
    if (streq(token, "light_blue")) return 9;
    if (streq(token, "light_green")) return 10;
    if (streq(token, "light_cyan")) return 11;
    if (streq(token, "light_red")) return 12;
    if (streq(token, "light_magenta")) return 13;
    if (streq(token, "yellow")) return 14;
    if (streq(token, "white")) return 15;
    return 7;
}
int streq(const char* a, const char* b) {
    int i = 0;
    while (a[i] && b[i]) {
        if (a[i] != b[i]) return 0;
        i++;
    }
    return a[i] == b[i];
}

// end color.preq 
// Including preq: vars.preq 
#define MAX_VARS 100
#define MAX_VAR_NAME 32
#define MAX_STRING_LENGTH 256

typedef struct {
    char name[MAX_VAR_NAME];
    int value;
    float float_value;
    char str_value[MAX_STRING_LENGTH];
    int is_string;
    int is_float;
    int is_initialized;
} Variable;

Variable variables[MAX_VARS];
int var_count = 0;

void init_vars() {
    var_count = 0;
    for (int i = 0; i < MAX_VARS; i++) {
        variables[i].is_initialized = 0;
        variables[i].is_string = 0;
        variables[i].is_float = 0;
    }
}

int find_var(const char* name) {
    for (int i = 0; i < var_count; i++) {
        if (streq(variables[i].name, name)) {
            return i;
        }
    }
    return -1;
}

int set_var(const char* name, int value) {
    int idx = find_var(name);
    if (idx == -1) {
        if (var_count >= MAX_VARS) return 0;
        idx = var_count;
        int i = 0;
        while (name[i] && i < MAX_VAR_NAME - 1) {
            variables[idx].name[i] = name[i];
            i++;
        }
        variables[idx].name[i] = '\0';
        var_count++;
    }
    variables[idx].value = value;
    variables[idx].is_string = 0;
    variables[idx].is_float = 0;
    variables[idx].is_initialized = 1;
    return 1;
}

int set_var_float(const char* name, float value) {
    int idx = find_var(name);
    if (idx == -1) {
        if (var_count >= MAX_VARS) return 0;
        idx = var_count;
        int i = 0;
        while (name[i] && i < MAX_VAR_NAME - 1) {
            variables[idx].name[i] = name[i];
            i++;
        }
        variables[idx].name[i] = '\0';
        var_count++;
    }
    variables[idx].float_value = value;
    variables[idx].is_string = 0;
    variables[idx].is_float = 1;
    variables[idx].is_initialized = 1;
    return 1;
}

int set_var_string(const char* name, const char* str) {
    int idx = find_var(name);
    if (idx == -1) {
        if (var_count >= MAX_VARS) return 0;
        idx = var_count;
        int i = 0;
        while (name[i] && i < MAX_VAR_NAME - 1) {
            variables[idx].name[i] = name[i];
            i++;
        }
        variables[idx].name[i] = '\0';
        var_count++;
    }
    int i = 0;
    while (str[i] && i < MAX_STRING_LENGTH - 1) {
        variables[idx].str_value[i] = str[i];
        i++;
    }
    variables[idx].str_value[i] = '\0';
    variables[idx].is_string = 1;
    variables[idx].is_float = 0;
    variables[idx].is_initialized = 1;
    return 1;
}

int get_var(const char* name) {
    int idx = find_var(name);
    if (idx != -1 && variables[idx].is_initialized && !variables[idx].is_string && !variables[idx].is_float) {
        return variables[idx].value;
    }
    return 0;
}

float get_var_float(const char* name) {
    int idx = find_var(name);
    if (idx != -1 && variables[idx].is_initialized && variables[idx].is_float) {
        return variables[idx].float_value;
    }
    return 0.0f;
}

char* get_var_string(const char* name) {
    int idx = find_var(name);
    if (idx != -1 && variables[idx].is_initialized && variables[idx].is_string) {
        return variables[idx].str_value;
    }
    return "";
}

int is_string_var(const char* name) {
    int idx = find_var(name);
    return (idx != -1 && variables[idx].is_initialized && variables[idx].is_string);
}

int is_float_var(const char* name) {
    int idx = find_var(name);
    return (idx != -1 && variables[idx].is_initialized && variables[idx].is_float);
} 
// Including preq: math.preq 
int add_int(int a, int b) { return a + b; }
int sub_int(int a, int b) { return a - b; }
int mul_int(int a, int b) { return a * b; }
int div_int(int a, int b) { return b != 0 ? a / b : 0; }
int mod_int(int a, int b) { return b != 0 ? a % b : 0; }

float add_float(float a, float b) { return a + b; }
float sub_float(float a, float b) { return a - b; }
float mul_float(float a, float b) { return a * b; }
float div_float(float a, float b) { return b != 0.0f ? a / b : 0.0f; }
float power_float(float base, float exp) {
    float result = 1.0f;
    for (int i = 0; i < (int)exp; i++) {
        result *= base;
    }
    return result;
}

// Helper functions for mixed arithmetic (original)
float add_mixed(const char* a, const char* b) {
    if (is_float_var(a) || is_float_var(b)) {
        float fa = is_float_var(a) ? get_var_float(a) : (float)get_var(a);
        float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
        return fa + fb;
    }
    return (float)(get_var(a) + get_var(b));
}

float sub_mixed(const char* a, const char* b) {
    if (is_float_var(a) || is_float_var(b)) {
        float fa = is_float_var(a) ? get_var_float(a) : (float)get_var(a);
        float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
        return fa - fb;
    }
    return (float)(get_var(a) - get_var(b));
}

float mul_mixed(const char* a, const char* b) {
    if (is_float_var(a) || is_float_var(b)) {
        float fa = is_float_var(a) ? get_var_float(a) : (float)get_var(a);
        float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
        return fa * fb;
    }
    return (float)(get_var(a) * get_var(b));
}

float div_mixed(const char* a, const char* b) {
    float fa = is_float_var(a) ? get_var_float(a) : (float)get_var(a);
    float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    return fb != 0.0f ? fa / fb : 0.0f;
}

int div_int_mixed(const char* a, const char* b) {
    int ia = get_var(a);
    int ib = get_var(b);
    return ib != 0 ? ia / ib : 0;
}

int mod_mixed(const char* a, const char* b) {
    int ia = get_var(a);
    int ib = get_var(b);
    return ib != 0 ? ia % ib : 0;
}

float power_mixed(const char* a, const char* b) {
    float base = is_float_var(a) ? get_var_float(a) : (float)get_var(a);
    float exp = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    float result = 1.0f;
    for (int i = 0; i < (int)exp; i++) {
        result *= base;
    }
    return result;
}

// Helper functions for left-to-right evaluation (new)
float add_mixed_float(float a, const char* b) {
    float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    return a + fb;
}

float sub_mixed_float(float a, const char* b) {
    float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    return a - fb;
}

float mul_mixed_float(float a, const char* b) {
    float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    return a * fb;
}

float div_mixed_float(float a, const char* b) {
    float fb = is_float_var(b) ? get_var_float(b) : (float)get_var(b);
    return fb != 0.0f ? a / fb : 0.0f;
}

// Helper functions for float + float (if needed)
float add_float_float(float a, float b) {
    return a + b;
}

float sub_float_float(float a, float b) {
    return a - b;
}

float mul_float_float(float a, float b) {
    return a * b;
}

float div_float_float(float a, float b) {
    return b != 0.0f ? a / b : 0.0f;
} 
// Including preq: input.preq 
#ifndef NULL
#define NULL ((void*)0)
#endif

#define KEYBOARD_DATA_PORT 0x60
#define KEYBOARD_STATUS_PORT 0x64
#define KEYBOARD_BUFFER_SIZE 256

char keyboard_buffer[KEYBOARD_BUFFER_SIZE];
int keyboard_buffer_start = 0;
int keyboard_buffer_end = 0;
int keyboard_buffer_count = 0;
int shift_pressed = 0;
int caps_lock = 0;
char scancode_to_ascii[] = {
    0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
    0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '-',
    0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
char scancode_to_ascii_shift[] = {
    0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
    0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',
    0, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '-',
    0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
unsigned char inb(unsigned short port) {
    unsigned char result;
    __asm__ volatile("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}
int keyboard_has_data() {
    return inb(KEYBOARD_STATUS_PORT) & 0x01;
}
unsigned char keyboard_read_scan_code() {
    return inb(KEYBOARD_DATA_PORT);
}

void process_scan_code(unsigned char scancode) {
    char ascii_char;
    if (scancode & 0x80) {
        unsigned char released_key = scancode & 0x7F;
        if (released_key == 0x2A || released_key == 0x36) {
            shift_pressed = 0;
        }
        return; 
    }
    switch (scancode) {
        case 0x2A: 
        case 0x36: 
            shift_pressed = 1;
            break;
            
        case 0x3A: 
            caps_lock = !caps_lock;
            break;
            
        case 0x0E: 
            if (keyboard_buffer_count < KEYBOARD_BUFFER_SIZE) {
                keyboard_buffer[keyboard_buffer_end] = '\b';
                keyboard_buffer_end = (keyboard_buffer_end + 1) % KEYBOARD_BUFFER_SIZE;
                keyboard_buffer_count++;
                if (cursor_x > 0) {
                    cursor_x--;
                    int offset = (cursor_y * VGA_WIDTH + cursor_x) * 2;
                    video_memory[offset] = ' ';
                    video_memory[offset + 1] = current_color;
                    update_cursor_position();
                }
            }
            break;
            
        case 0x1C: 
            ascii_char = '\n';
            if (keyboard_buffer_count < KEYBOARD_BUFFER_SIZE) {
                keyboard_buffer[keyboard_buffer_end] = ascii_char;
                keyboard_buffer_end = (keyboard_buffer_end + 1) % KEYBOARD_BUFFER_SIZE;
                keyboard_buffer_count++;
            }
            print_char('\n');
            break;
            
        default:
            if (scancode < 58) {
                if (shift_pressed || caps_lock) {
                    ascii_char = scancode_to_ascii_shift[scancode];
                } else {
                    ascii_char = scancode_to_ascii[scancode];
                }
                
                if (ascii_char != 0 && ascii_char != '\b') {
                    if (keyboard_buffer_count < KEYBOARD_BUFFER_SIZE) {
                        keyboard_buffer[keyboard_buffer_end] = ascii_char;
                        keyboard_buffer_end = (keyboard_buffer_end + 1) % KEYBOARD_BUFFER_SIZE;
                        keyboard_buffer_count++;
                        print_char(ascii_char);
                    }
                }
            }
            break;
    }
}
void keyboard_poll() {
    while (keyboard_has_data()) {
        unsigned char scancode = keyboard_read_scan_code();
        process_scan_code(scancode);
    }
}
char get_char() {
    char c;
    while (keyboard_buffer_count == 0) {
        keyboard_poll();
        for (volatile int i = 0; i < 1000; i++);
    }
    
    c = keyboard_buffer[keyboard_buffer_start];
    keyboard_buffer_start = (keyboard_buffer_start + 1) % KEYBOARD_BUFFER_SIZE;
    keyboard_buffer_count--;
    
    return c;
}
char* get_input_string(const char* prompt) {
    static char buffer[256];
    int index = 0;
    char c;
    if (prompt != NULL && prompt[0] != '\0') {
        print_string(prompt);
    }
    while (index < 255) {
        c = get_char();
        
        if (c == '\n') {
            break;
        } else if (c == '\b') {
            if (index > 0) {
                index--;
            }
        } else {
            buffer[index++] = c;
        }
    }
    
    buffer[index] = '\0';
    return buffer;
}
void keyboard_init() {
    keyboard_buffer_start = 0;
    keyboard_buffer_end = 0;
    keyboard_buffer_count = 0;
    shift_pressed = 0;
    caps_lock = 0;
} 
// actual stuff 
void cls(const char* args); 
void print(const char* args); 
void var(const char* args); 
void math(const char* args); 
char* input(const char* args); 
 
void kernel_main() { 
    cls(""); 
    init_vars(); 
    keyboard_init(); 
    char* shutup = input("What do you want to add 10 to "); set_var_string("shutup", shutup); 
    set_var("shutp", 10); 
    set_var("shutup_num", parse_int(shutup)); 
    float temp = (float)get_var("shutup_num")+(float)get_var("shutp"); print_float(temp); print_char('\n'); 
} 
 
// plugs for cls 
void cls(const char* args) { 
     clear_screen(); 
} 
 
// plugs for print 
void print(const char* args) { 
     print_string(args); 
} 
 
// plugs for input 
char* input(const char* args) { 
     keyboard_init();  return get_input_string(args);; 
} 
 
