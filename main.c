#include <stdio.h>
#include <stdbool.h>

extern void routine_init(void);
extern void routine(void (*f)(void));
extern int  routine_await(void);

void routine_0(void)
{
    for (int i = 0; i < 12; ++i) {
        printf("%d\n", i);
        routine_await();
    }
}

void routine_1(void)
{
    for (int i = 0; i < 20; ++i) {
        printf("%d\n", i);
        routine_await();
    }
}

void routine_2(void)
{
    for (int i = 20; i > 0; --i) {
        printf("%d\n", i);
        routine_await();
    }
}

int main()
{
    routine_init();
    routine(routine_0);
    routine(routine_1);
    routine(routine_2);
    while (true) {
        if(!routine_await()) break;
    };
    printf("finish\n");
    return 0;
}