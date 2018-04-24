;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Handling level files
;===================================================================================================
LOCALS @@

; Box size
SCRN_BOX_WIDTH          = 16
SCRN_BOX_HEIGHT         = 16
; Game area
SCRN_DRAW_AREA_WIDTH    = 320
SCRN_DRAW_AREA_HEIGHT   = 176
; Number of boxes in each row and col
SCRN_NUM_BOXES_WIDTH    = SCRN_DRAW_AREA_WIDTH/SCRN_BOX_WIDTH
SCRN_NUM_BOXES_HEIGHT   = SCRN_DRAW_AREA_HEIGHT/SCRN_BOX_HEIGHT
; Array size
SCRN_ARRAY_SIZE         = SCRN_NUM_BOXES_WIDTH * SCRN_NUM_BOXES_HEIGHT
; LVL file sizes
LVL_FILE_NUM_LINES      = SCRN_NUM_BOXES_HEIGHT                 ; numberof lines in a lvl file
LVL_FILE_LINE_LEN       = SCRN_NUM_BOXES_WIDTH + 2              ; number of chars in a lvl line
LVL_FILE_SIZE           = LVL_FILE_LINE_LEN*LVL_FILE_NUM_LINES

; Game objects
OBJ_BOX_ON_TARGET           = 5
OBJ_TARGET                  = 4     ; '#'
OBJ_PLAYER                  = 3     ; '@'
OBJ_BOX                     = 2     ; '+'
OBJ_WALL                    = 1     ; '*'
OBJ_FLOOR                   = 0     ; ' '
OBJ_INVALID                 = -1

; Possible directions
DIR_UP                  = 1
DIR_DOWN                = 2
DIR_LEFT                = 3
DIR_RIGHT               = 4
DIR_INVALID             = 10

DATASEG

    fileLevel1      db          "lvl\\lvl1.dat",0
    fileLevel2      db          "lvl\\lvl2.dat",0

    levelLine       db          LVL_FILE_LINE_LEN dup(0)
    levelScreen     db          SCRN_ARRAY_SIZE dup(0)

    ErrLoadLevel    db          "Error loading level file","$"
    currentRow      dw          0
    currentCol      dw          0
    numTargets      dw          0


CODESEG

;------------------------------------------------------------------------
; init_level: 
;
;------------------------------------------------------------------------
MACRO init_level X1, X2
    mov [currentCol],0
    mov [currentRow],0
    mov [numTargets],0
ENDM
;------------------------------------------------------------------------
; ReadLevelFile: 
; 
; Input:
;     push offset path 
;     call ReadLevelFile
; 
; Output: AX TRUE/FALSE
;------------------------------------------------------------------------
PROC ReadLevelFile
    push bp
    mov bp,sp
    push si di 
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => lvlFilePath
    ; saved registers
 
    ;{
    lvlFilePath        equ        [word bp+4]
    ;}


    mov si, lvlFilePath
    m_fsize si ds

    cmp ax, LVL_FILE_SIZE
    jne @@badSize

    ; open file
    m_fopen si, ds

    mov cx, LVL_FILE_NUM_LINES
    mov di, 0           ; current line
@@rd:    
    ; read single line, including new line (0A,0D) chars at the end
    mov si, offset levelLine
    m_fread LVL_FILE_LINE_LEN, si, ds

    push di
    call ParseLevelData

    inc di
    loop @@rd

    m_fclose
    
    mov ax, TRUE
    jmp @@end
    
@@badSize:
    mov ax, FALSE    
 
@@end:
    pop di si
    mov sp,bp
    pop bp
    ret 2
ENDP ReadLevelFile
;------------------------------------------------------------------------
; ParseLevelData: parsing the data in levelLine into the array levelScreen
; 
; Input:
;     push  current_line
;     call ParseLevelData
; 
; Output: None
;------------------------------------------------------------------------
PROC ParseLevelData
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => current line
    ; saved registers
 
    ;{
    curLine        equ        [word bp+4]
    ;}

    ; si = levelScreen + (curLine * SCRN_BOX_WIDTH)
    ; points to the array address of the current row 
    mov si, offset levelScreen
    mov ax, curLine
    mov bx, SCRN_NUM_BOXES_WIDTH
    mul bl
    add si, ax


    xor bx,bx                   ; col index
    xor ax,ax
    mov cx, SCRN_NUM_BOXES_WIDTH
    mov di, offset levelLine
@@parse:
    mov al,[BYTE di]
    cmp al, '*'
    jne @@box

    ; Found an *
    mov [BYTE si], OBJ_WALL
    jmp @@cont

@@box:
    cmp al,'+'
    jne @@target

    mov [BYTE si], OBJ_BOX
    jmp @@cont

@@target:
    cmp al,'#'
    jne @@player

    mov [BYTE si], OBJ_TARGET
    inc [numTargets]             ; count targets
    jmp @@cont

@@player:
    cmp al,'@'
    jne @@space

    mov [BYTE si], OBJ_PLAYER
    mov dx, curLine
    mov [currentRow], dx          ; row
    mov [currentCol], bx          ; col
    jmp @@cont

@@space:
    mov [BYTE si], OBJ_FLOOR
@@cont:
    inc si
    inc di
    inc bx
    loop @@parse

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP ParseLevelData