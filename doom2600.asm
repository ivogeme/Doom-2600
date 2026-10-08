; =============================================================================
; DOOM 2600 - PROTÓTIPO FALSO-3D
; Atari 2600 / 6507
; DASM
;
; Recursos:
;   - Mapa 8x8
;   - Jogador X/Y
;   - Direção 0-3
;   - Movimento com colisão
;   - Rotação
;   - Raycast simplificado
;   - Parede em perspectiva
;   - Tiro + áudio
;   - Frame NTSC de 262 linhas
;
; Direções:
;   0 = Norte
;   1 = Leste
;   2 = Sul
;   3 = Oeste
;
; Mapa:
;   1 = parede
;   0 = espaço livre
; =============================================================================

    processor 6502

    include "vcs.h"
    include "macro.h"


; =============================================================================
; RAM
; =============================================================================

    SEG.U variables
    ORG $80

PosX:           .byte
PosY:           .byte
Dir:            .byte

TempX:          .byte
TempY:          .byte
Temp:           .byte

RayDist:        .byte
WallFound:      .byte

LineCounter:    .byte
TopLine:        .byte
BottomLine:     .byte

SoundTimer:     .byte


; =============================================================================
; ROM
; =============================================================================

    SEG code
    ORG $F000


; =============================================================================
; RESET
; =============================================================================

Start:

    SEI
    CLD

    LDX #$FF
    TXS

    ; ---------------------------------------------------------
    ; Inicialização básica do TIA
    ; ---------------------------------------------------------

    LDA #0

    STA VSYNC
    STA VBLANK
    STA PF0
    STA PF1
    STA PF2
    STA GRP0
    STA GRP1
    STA ENAM0
    STA ENAM1
    STA ENABL

    STA AUDV0
    STA AUDV1

    ; Playfield refletido
    LDA #%00000001
    STA CTRLPF

    ; ---------------------------------------------------------
    ; Cores
    ; ---------------------------------------------------------

    LDA #$00
    STA COLUBK

    LDA #$C2
    STA COLUP0

    LDA #$1C
    STA COLUP1

    LDA #$0E
    STA COLUPF

    ; ---------------------------------------------------------
    ; Estado inicial
    ; ---------------------------------------------------------

    LDA #1
    STA PosX

    LDA #1
    STA PosY

    LDA #0
    STA Dir

    STA SoundTimer

    ; ---------------------------------------------------------
    ; Espera pelo RESET do console
    ; ---------------------------------------------------------

WaitReset:

    LDA SWCHB
    AND #%00000001

    BNE WaitReset


; =============================================================================
; LOOP PRINCIPAL
; =============================================================================

StartGame:

    ; posição inicial
    LDA #1
    STA PosX
    STA PosY

    LDA #0
    STA Dir

MainLoop:

    JSR FrameSync

    JSR CheckInput

    JSR UpdateAudio

    JSR RenderScene

    JMP MainLoop


; =============================================================================
; FRAME NTSC
;
; 3 linhas VSYNC
; 37 linhas VBLANK
; 192 linhas visíveis
; 30 linhas overscan
;
; Total:
;
; 3 + 37 + 192 + 30 = 262
; =============================================================================

FrameSync:

    ; ---------------------------------------------------------
    ; VSYNC
    ; ---------------------------------------------------------

    LDA #2
    STA VSYNC

    STA WSYNC
    STA WSYNC
    STA WSYNC

    LDA #0
    STA VSYNC

    ; ---------------------------------------------------------
    ; VBLANK
    ; ---------------------------------------------------------

    LDA #2
    STA VBLANK

    LDX #37

VBlankLoop:

    STA WSYNC

    DEX
    BNE VBlankLoop

    ; ---------------------------------------------------------
    ; Início da imagem visível
    ; ---------------------------------------------------------

    LDA #0
    STA VBLANK

    RTS


; =============================================================================
; INPUT
; =============================================================================

CheckInput:

    ; ---------------------------------------------------------
    ; Direita
    ; SWCHA bit 0
    ; ---------------------------------------------------------

    LDA SWCHA
    AND #%00000001

    BNE CheckLeft

    JSR TurnRight

    RTS


CheckLeft:

    LDA SWCHA
    AND #%00000010

    BNE CheckForward

    JSR TurnLeft

    RTS


CheckForward:

    LDA SWCHA
    AND #%00001000

    BNE CheckFire

    JSR MoveForward

    RTS


CheckFire:

    LDA INPT4

    BMI NoFire

    JSR FireWeapon

NoFire:

    RTS


; =============================================================================
; ROTAÇÃO DIREITA
; =============================================================================

TurnRight:

    LDA Dir

    CLC
    ADC #1

    CMP #4
    BNE StoreRight

    LDA #0

StoreRight:

    STA Dir

    RTS


; =============================================================================
; ROTAÇÃO ESQUERDA
; =============================================================================

TurnLeft:

    LDA Dir

    BEQ LeftWrap

    SEC
    SBC #1

    STA Dir

    RTS


LeftWrap:

    LDA #3
    STA Dir

    RTS


; =============================================================================
; MOVIMENTO PARA FRENTE
; =============================================================================

MoveForward:

    ; ---------------------------------------------------------
    ; Copia posição atual
    ; ---------------------------------------------------------

    LDA PosX
    STA TempX

    LDA PosY
    STA TempY

    ; ---------------------------------------------------------
    ; Norte
    ; ---------------------------------------------------------

    LDA Dir

    CMP #0
    BNE MoveRight

    LDA TempY
    BEQ MovementBlocked

    DEC TempY

    JMP TestMovement


; -------------------------------------------------------------
; Leste
; -------------------------------------------------------------

MoveRight:

    CMP #1
    BNE MoveDown

    LDA TempX
    CMP #7
    BEQ MovementBlocked

    INC TempX

    JMP TestMovement


; -------------------------------------------------------------
; Sul
; -------------------------------------------------------------

MoveDown:

    CMP #2
    BNE MoveLeft

    LDA TempY
    CMP #7
    BEQ MovementBlocked

    INC TempY

    JMP TestMovement


; -------------------------------------------------------------
; Oeste
; -------------------------------------------------------------

MoveLeft:

    LDA TempX

    BEQ MovementBlocked

    DEC TempX


; =============================================================================
; TESTA A CÉLULA
; =============================================================================

TestMovement:

    ; ---------------------------------------------------------
    ; Y -> linha
    ; ---------------------------------------------------------

    LDY TempY

    LDA MapData,Y

    ; ---------------------------------------------------------
    ; X -> bit
    ;
    ; coluna 0 = bit 7
    ; coluna 1 = bit 6
    ; ...
    ; coluna 7 = bit 0
    ; ---------------------------------------------------------

    LDX TempX

ShiftMovement:

    CPX #0
    BEQ CheckMovementBit

    LSR

    DEX

    JMP ShiftMovement


CheckMovementBit:

    AND #%00000001

    ; 1 = parede
    BNE MovementBlocked

    ; ---------------------------------------------------------
    ; Caminho livre
    ; ---------------------------------------------------------

    LDA TempX
    STA PosX

    LDA TempY
    STA PosY


MovementBlocked:

    RTS


; =============================================================================
; RAYCAST
;
; Verifica até quatro células à frente.
;
; RayDist:
;
; 1 = parede imediatamente à frente
; 2 = parede a duas células
; 3 = parede a três células
; 4 = parede a quatro células
; 0 = nenhuma parede encontrada
; =============================================================================

CastRay:

    LDA #0
    STA RayDist

    LDA PosX
    STA TempX

    LDA PosY
    STA TempY

    LDX #4


RayStep:

    ; ---------------------------------------------------------
    ; Avança uma célula
    ; ---------------------------------------------------------

    LDA Dir

    CMP #0
    BNE RayRight

    DEC TempY
    JMP RayBounds


RayRight:

    CMP #1
    BNE RayDown

    INC TempX
    JMP RayBounds


RayDown:

    CMP #2
    BNE RayLeft

    INC TempY
    JMP RayBounds


RayLeft:

    DEC TempX


; =============================================================================
; LIMITES DO RAYCAST
; =============================================================================

RayBounds:

    ; ---------------------------------------------------------
    ; X < 0 ou X >= 8
    ;
    ; Como usamos unsigned:
    ; 00-07 = válido
    ; 08+   = fora
    ;
    ; Para oeste, um DEC de 0 vira FF.
    ; ---------------------------------------------------------

    LDA TempX
    CMP #8
    BCS RayWallEdge


    LDA TempY
    CMP #8
    BCS RayWallEdge

    ; ---------------------------------------------------------
    ; Consulta mapa
    ; ---------------------------------------------------------

    LDY TempY

    LDA MapData,Y

    LDX TempX

RayShift:

    CPX #0
    BEQ RayBit

    LSR

    DEX

    JMP RayShift


RayBit:

    AND #%00000001

    BEQ RayContinue

    ; ---------------------------------------------------------
    ; Encontrou parede
    ; ---------------------------------------------------------

    STX Temp

    LDA #4
    SEC
    SBC XRayCounter
    STA RayDist

    RTS


RayContinue:

    ; Próximo passo
    DEX

    ; O X acima não é nosso contador real.
    ; Recarrega o contador de distância.
    ; A rotina abaixo usa RayDist como contador.

    LDA RayDist
    CLC
    ADC #1
    STA RayDist

    CMP #4
    BCS RayNothing

    JMP RayStep


RayWallEdge:

    ; Borda do mapa é tratada como parede.
    LDA #1
    STA WallFound

    LDA RayDist

    CLC
    ADC #1

    STA RayDist

    RTS


RayNothing:

    LDA #0
    STA RayDist

    RTS


; =============================================================================
; RENDER SCENE
; =============================================================================

RenderScene:

    ; ---------------------------------------------------------
    ; Descobre distância da parede
    ; ---------------------------------------------------------

    JSR CastRay

    ; ---------------------------------------------------------
    ; Define tamanho da parede
    ;
    ; Distância 1 -> parede muito grande
    ; Distância 2 -> grande
    ; Distância 3 -> média
    ; Distância 4 -> pequena
    ; Nenhuma    -> pequena
    ; ---------------------------------------------------------

    LDA RayDist

    CMP #1
    BEQ WallNear

    CMP #2
    BEQ WallMediumNear

    CMP #3
    BEQ WallMedium

    ; ---------------------------------------------------------
    ; Distância 4 / nenhuma
    ; ---------------------------------------------------------

    LDA #80
    STA TopLine

    LDA #112
    STA BottomLine

    JMP BeginRender


WallMedium:

    LDA #64
    STA TopLine

    LDA #128
    STA BottomLine

    JMP BeginRender


WallMediumNear:

    LDA #40
    STA TopLine

    LDA #152
    STA BottomLine

    JMP BeginRender


WallNear:

    LDA #20
    STA TopLine

    LDA #172
    STA BottomLine


; =============================================================================
; RENDERIZA 192 LINHAS
; =============================================================================

BeginRender:

    LDX #0
    STX LineCounter


RenderLoop:

    STA WSYNC

    ; ---------------------------------------------------------
    ; Fundo
    ; ---------------------------------------------------------

    LDA #0
    STA PF0
    STA PF1
    STA PF2

    ; ---------------------------------------------------------
    ; Se a linha estiver dentro da parede,
    ; desenha o playfield.
    ; ---------------------------------------------------------

    LDA LineCounter

    CMP TopLine
    BCC RenderNextLine

    LDA BottomLine
    CMP LineCounter
    BCC RenderNextLine

    ; ---------------------------------------------------------
    ; Parede
    ; ---------------------------------------------------------

    LDA #$F0
    STA PF0

    LDA #$FF
    STA PF1

    LDA #$FF
    STA PF2


RenderNextLine:

    INC LineCounter

    LDA LineCounter

    CMP #192
    BNE RenderLoop


; =============================================================================
; HUD / CORES
; =============================================================================

    ; ---------------------------------------------------------
    ; Fundo
    ; ---------------------------------------------------------

    LDA PosX
    ASL
    ASL
    STA COLUBK

    ; ---------------------------------------------------------
    ; Parede
    ; ---------------------------------------------------------

    LDA PosY
    ASL
    ASL
    ORA #$20
    STA COLUPF


; =============================================================================
; OVERSCAN
; =============================================================================

    LDA #2
    STA VBLANK

    LDX #30

OverscanLoop:

    STA WSYNC

    DEX
    BNE OverscanLoop

    RTS


; =============================================================================
; TIRO
; =============================================================================

FireWeapon:

    LDA SoundTimer
    BNE FireAlreadyActive

    ; Volume
    LDA #15
    STA AUDV0

    ; Tipo de áudio
    LDA #3
    STA AUDC0

    ; Frequência
    LDA #10
    STA AUDF0

    ; Duração
    LDA #10
    STA SoundTimer

FireAlreadyActive:

    RTS


; =============================================================================
; ÁUDIO
; =============================================================================

UpdateAudio:

    LDA SoundTimer

    BEQ AudioOff

    DEC SoundTimer

    RTS


AudioOff:

    LDA #0
    STA AUDV0

    RTS


; =============================================================================
; MAPA 8x8
;
; 1 = parede
; 0 = espaço
;
;       0 1 2 3 4 5 6 7
;
; 0     █ █ █ █ █ █ █ █
; 1     █ . . . . . . █
; 2     █ . █ . █ . . █
; 3     █ . █ . █ █ . █
; 4     █ . . . . . . █
; 5     █ █ █ █ █ █ █ █
; 6     █ █ █ █ █ █ █ █
; 7     █ █ █ █ █ █ █ █
;
; =============================================================================

MapData:

    .byte %11111111
    .byte %10000001
    .byte %10101001
    .byte %10101101
    .byte %10000001
    .byte %11111111
    .byte %11111111
    .byte %11111111


; =============================================================================
; VETORES
; =============================================================================

    ORG $FFFC

    .word Start
    .word Start-----------------------------------------

    LDA #0

    STA PF0
    STA PF1
    STA PF2


    ; -------------------------------------------------------------------------
    ; Verifica se estamos dentro da parede
    ; -------------------------------------------------------------------------

    LDA LineCounter

    CMP TopLine
    BCC RenderNextLine


    LDA BottomLine

    CMP LineCounter
    BCC RenderNextLine


    ; -------------------------------------------------------------------------
    ; Parede
    ; -------------------------------------------------------------------------

    LDA #$F0
    STA PF0

    LDA #$FF
    STA PF1

    LDA #$FF
    STA PF2


; =============================================================================
; PRÓXIMA LINHA
; =============================================================================

RenderNextLine:

    INC LineCounter

    LDA LineCounter

    CMP #192

    BNE RenderLoop


; =============================================================================
; HUD / CORES
; =============================================================================

    ; -------------------------------------------------------------------------
    ; Cor do fundo baseada na posição X
    ; -------------------------------------------------------------------------

    LDA PosX

    ASL
    ASL

    STA COLUBK


    ; -------------------------------------------------------------------------
    ; Cor do playfield baseada na posição Y
    ; -------------------------------------------------------------------------

    LDA PosY

    ASL
    ASL

    ORA #$20

    STA COLUPF


; =============================================================================
; OVERSCAN
; =============================================================================

    LDA #2
    STA VBLANK

    LDX #30


OverscanLoop:

    STA WSYNC

    DEX

    BNE OverscanLoop

    RTS


; =============================================================================
; TIRO
; =============================================================================

FireWeapon:

    ; -------------------------------------------------------------------------
    ; Se já existe som, não reinicia
    ; -------------------------------------------------------------------------

    LDA SoundTimer

    BNE FireAlreadyActive


    ; -------------------------------------------------------------------------
    ; Volume máximo
    ; -------------------------------------------------------------------------

    LDA #15
    STA AUDV0


    ; -------------------------------------------------------------------------
    ; Tipo de som
    ; -------------------------------------------------------------------------

    LDA #3
    STA AUDC0


    ; -------------------------------------------------------------------------
    ; Frequência
    ; -------------------------------------------------------------------------

    LDA #10
    STA AUDF0


    ; -------------------------------------------------------------------------
    ; Duração
    ; -------------------------------------------------------------------------

    LDA #10
    STA SoundTimer


FireAlreadyActive:

    RTS


; =============================================================================
; ATUALIZA ÁUDIO
; =============================================================================

UpdateAudio:

    LDA SoundTimer

    BEQ AudioOff

    DEC SoundTimer

    RTS


AudioOff:

    LDA #0
    STA AUDV0

    RTS


; =============================================================================
; MAPA 8x8
;
; 1 = parede
; 0 = espaço livre
;
;       0 1 2 3 4 5 6 7
;
; 0     █ █ █ █ █ █ █ █
; 1     █ . . . . . . █
; 2     █ . █ . █ . . █
; 3     █ . █ . █ █ . █
; 4     █ . . . . . . █
; 5     █ █ █ █ █ █ █ █
; 6     █ █ █ █ █ █ █ █
; 7     █ █ █ █ █ █ █ █
;
; =============================================================================

MapData:

    .byte %11111111
    .byte %10000001
    .byte %10101001
    .byte %10101101
    .byte %10000001
    .byte %11111111
    .byte %11111111
    .byte %11111111


; =============================================================================
; VETORES DO 6502
; =============================================================================

    ORG $FFFC

    .word Start
    .word Start