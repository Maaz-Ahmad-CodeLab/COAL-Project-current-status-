[org 0x0100]

%macro RECT 5
    mov ax, %1
    mov bx, %2
    mov dx, %3
    mov cx, %4
    mov si, %5
    call drawRect
%endmacro

jmp start

drawSky:
    pusha
    mov cx, 32000
    mov ax, 0xa000
    mov es, ax
    mov di, 0
    mov al, 54
    rep stosb
    popa
    ret

drawGrass:
    pusha
    mov cx, 32000
    mov ax, 0xa000
    mov es, ax
    mov di, 32000
    mov al, 10
    rep stosb
    popa
    ret

hline:
    push dx
    push si
    mov dx, [roadY]
    mov si, 1
    call drawRect
    pop si
    pop dx
    ret

drawRoad:
    pusha
    mov word [roadY], 100

road_loop:
    mov ax, [roadY]
    sub ax, 100
    mov [roadRel], ax

    ; Calculate road width and force it to be even for symmetrical, smooth edges
    mov bx, 3
    mul bx
    add ax, 20
    and ax, 0xFFFE
    mov [roadW], ax

    ; Center the road around X = 160
    shr ax, 1
    mov bx, 160
    sub bx, ax
    mov [roadL], bx

    ; 1. Clean 1px black outer borders
    xor ax, ax
    mov bx, [roadL]
    dec bx
    mov cx, 1
    call hline

    xor ax, ax
    mov bx, [roadL]
    add bx, [roadW]
    mov cx, 1
    call hline

    ; 2. Main asphalt surface (color 8 = dark gray)
    mov ax, 8
    mov bx, [roadL]
    mov cx, [roadW]
    call hline

    ; 3. Clean, uniform 2px white inner shoulder lines
    mov ax, 15
    mov bx, [roadL]
    mov cx, 2
    call hline

    mov ax, 15
    mov bx, [roadL]
    add bx, [roadW]
    sub bx, 2
    mov cx, 2
    call hline

    ; 4. Uniform 2px dashed lane dividers
    mov ax, [roadY]
    test ax, 8
    jnz skip_dash

    mov ax, [roadW]
    xor dx, dx
    mov bx, 3
    div bx
    mov [roadThird], ax

    mov bx, [roadL]
    add bx, ax
    mov ax, 15
    mov cx, 2
    call hline

    mov ax, [roadThird]
    shl ax, 1
    mov bx, [roadL]
    add bx, ax
    mov ax, 15
    mov cx, 2
    call hline

skip_dash:
    inc word [roadY]
    cmp word [roadY], 175
    jl road_loop
    popa
    ret

drawBonnetAndDash:
    pusha
    mov ax, 0xa000
    mov es, ax
    mov dx, 140

bonnet_loop:
    mov ax, dx
    sub ax, 140
    mov bx, 14
    push dx
    mul bx
    pop dx
    add ax, 100
    mov cx, ax
    cmp cx, 320
    jle width_ok
    mov cx, 320

width_ok:
    mov bx, cx
    shr bx, 1
    mov ax, 160
    sub ax, bx
    mov bx, ax
    push dx
    mov ax, 320
    mul dx
    add ax, bx
    mov di, ax
    pop dx
    mov al, 42
    rep stosb
    inc dx
    cmp dx, 175
    jl bonnet_loop

    mov dx, 175

dash_loop:
    push dx
    mov ax, 320
    mul dx
    mov di, ax
    pop dx
    mov cx, 320
    mov al, 0
    rep stosb
    inc dx
    cmp dx, 200
    jl dash_loop
    popa
    ret

drawTrafficCar:
    pusha
    mov ax, 0xa000
    mov es, ax
    mov dx, 120
    mov bx, 15

car_loop:
    push dx
    push ax
    mov ax, 320
    mul dx
    add ax, 150
    mov di, ax
    pop ax
    pop dx
    mov cx, 20
    mov al, 1
    rep stosb
    inc dx
    dec bx
    jnz car_loop

    mov di, 320 * 132 + 152
    mov al, 4
    mov byte [es:di], al
    mov byte [es:di+1], al
    mov di, 320 * 132 + 166
    mov byte [es:di], al
    mov byte [es:di+1], al
    popa
    ret

drawRect:
    pusha
    mov bp, ax

rect_row:
    push cx
    push dx
    mov ax, 320
    mul dx
    add ax, bx
    mov di, ax
    mov ax, 0xa000
    mov es, ax
    mov ax, bp
    rep stosb
    pop dx
    pop cx
    inc dx
    dec si
    jnz rect_row
    popa
    ret

drawRing:
    pusha
    mov [ringColor], al
    mov [cenX], bx
    mov [cenY], dx
    mov [rad], si
    mov ax, si
    mul ax
    mov [outR2], ax
    mov ax, si
    sub ax, cx
    mul ax
    mov [inR2], ax
    mov ax, 0xa000
    mov es, ax
    mov bp, si
    neg bp

ring_y:
    mov si, [rad]
    neg si

ring_x:
    mov ax, bp
    imul ax
    mov bx, ax
    mov ax, si
    imul ax
    add bx, ax
    cmp bx, [outR2]
    ja ring_skip
    cmp bx, [inR2]
    jb ring_skip
    mov ax, [cenY]
    add ax, bp
    mov dx, 320
    mul dx
    add ax, [cenX]
    add ax, si
    mov di, ax
    mov al, [ringColor]
    mov [es:di], al

ring_skip:
    inc si
    cmp si, [rad]
    jle ring_x
    inc bp
    cmp bp, [rad]
    jle ring_y
    popa
    ret

gotoRC:
    pusha
    mov ah, 02h
    mov bh, 0
    int 0x10
    popa
    ret

putc:
    pusha
    mov ah, 0Eh
    mov bh, 0
    mov bl, [txtColor]
    int 0x10
    popa
    ret

printStr:
    pusha

ps_next:
    lodsb
    or al, al
    jz ps_done
    call putc
    jmp ps_next

ps_done:
    popa
    ret

printDec:
    pusha
    mov si, cx
    mov bx, 10

pd_div:
    xor dx, dx
    div bx
    push dx
    loop pd_div
    mov cx, si

pd_out:
    pop ax
    add al, '0'
    call putc
    loop pd_out
    popa
    ret

drawUI:
    pusha
    RECT 0, 10, 20, 6, 100
    RECT 4, 10, 70, 6, 50
    RECT 8, 200, 185, 40, 6
    RECT 2, 200, 185, 20, 6
    mov byte [txtColor], 15
    mov dh, 22
    mov dl, 25
    call gotoRC
    mov si, strFuel
    call printStr
    mov byte [txtColor], 12
    mov dh, 23
    mov dl, 24
    call gotoRC
    mov si, strE
    call printStr
    mov byte [txtColor], 10
    mov dh, 23
    mov dl, 30
    call gotoRC
    mov si, strF
    call printStr
    mov bx, 275
    mov dx, 165
    mov si, 25
    mov cx, 4
    mov al, 7
    call drawRing
    RECT 7, 254, 164, 43, 3
    RECT 7, 274, 166, 3, 20
    mov bx, 275
    mov dx, 165
    mov si, 7
    mov cx, 7
    mov al, 8
    call drawRing
    popa
    ret

drawSpeed:
    pusha
    RECT 8, 116, 180, 72, 16
    mov dh, 23
    mov dl, 15
    call gotoRC
    mov byte [txtColor], 15
    mov ax, [speed]
    mov cx, 3
    call printDec
    mov byte [txtColor], 7
    mov si, strKmh
    call printStr
    popa
    ret

drawDistance:
    pusha
    RECT 0, 2, 4, 118, 14
    mov dh, 1
    mov dl, 1
    call gotoRC
    mov byte [txtColor], 7
    mov si, strDist
    call printStr
    mov byte [txtColor], 15
    mov ax, [distHi]
    xor dx, dx
    mov bx, 10
    div bx
    xor dx, dx
    mov bx, 100
    div bx
    push dx
    mov cx, 2
    call printDec
    mov al, '.'
    call putc
    pop ax
    mov cx, 2
    call printDec
    mov byte [txtColor], 7
    mov si, strKm
    call printStr
    popa
    ret

start:
    cld
    mov ah, 00h
    mov al, 13h
    int 0x10

    call drawSky
    call drawGrass
    call drawRoad
    call drawTrafficCar
    call drawBonnetAndDash
    call drawUI
    call drawSpeed
    call drawDistance

wait_key:
    mov ah, 00h
    int 0x16

exit_prog:
    mov ah, 00h
    mov al, 03h
    int 0x10
    mov ax, 0x4c00
    int 0x21

cenX      dw 0
cenY      dw 0
rad       dw 0
outR2     dw 0
inR2      dw 0
ringColor db 0
roadY     dw 0
roadRel   dw 0
roadW     dw 0
roadL     dw 0
roadThird dw 0
speed     dw 0
distHi    dw 0
txtColor  db 15
strDist   db 'DIST ', 0
strKm     db ' KM', 0
strKmh    db ' KM/H', 0
strFuel   db 'FUEL', 0
strE      db 'E', 0
strF      db 'F', 0