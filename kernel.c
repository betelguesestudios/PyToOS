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
            video_memory[offset + 1] = current_color;  
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
    video_memory[offset + 1] = current_color; 
    
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
void set_text_color(unsigned char foreground, unsigned char background) {
    current_color = (background << 4) | (foreground & 0x0F);
}
unsigned char parse_int(const char* str) {
    unsigned char value = 0;
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

typedef struct {
    char name[MAX_VAR_NAME];
    int value;
    int is_initialized;
} Variable;

Variable variables[MAX_VARS];
int var_count = 0;

void init_vars() {
    var_count = 0;
    for (int i = 0; i < MAX_VARS; i++) {
        variables[i].is_initialized = 0;
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
    variables[idx].is_initialized = 1;
    return 1;
}

int get_var(const char* name) {
    int idx = find_var(name);
    if (idx != -1 && variables[idx].is_initialized) {
        return variables[idx].value;
    }
    return 0;
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
// Including preq: math.preq 
int add_int(int a, int b) { return a + b; }
int sub_int(int a, int b) { return a - b; }
int mul_int(int a, int b) { return a * b; }
int div_int(int a, int b) { return b != 0 ? a / b : 0; }
int mod_int(int a, int b) { return b != 0 ? a % b : 0; } 
// actual stuff 
void cls(const char* args); 
void setfg(const char* args); 
void printvar(const char* args); 
void print(const char* args); 
void var(const char* args); 
void math(const char* args); 
 
void kernel_main() { 
    cls(""); 
    init_vars(); 
    set_var("x", 10); 
    set_var("y", 20); 
    set_var("result", 0); 
    setfg("green"); 
    set_var("result", add_int(get_var("x"), get_var("y"))); 
    print_int(get_var("result")); print_char('\n'); 
    set_var("result", sub_int(get_var("y"), get_var("x"))); 
    print_int(get_var("result")); print_char('\n'); 
    print_string("Hello World\n"); 
} 
 
// plugs for cls 
void cls(const char* args) { 
     clear_screen(); 
} 
 
// plugs for setfg 
void setfg(const char* args) { 
     set_foreground(parse_color(args)); 
} 
 
// plugs for print 
void print(const char* args) { 
     print_string(args); 
} 
 
