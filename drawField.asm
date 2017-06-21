drawfield_loc = $
relocate(cursorImage)

DrawField:
    ld b, (ix+OFFSET_X)                                         ; We start with the shadow registers active
    bit 4, b
    ld a, 16
    ld c, 028h
    jr z, +_
    ld a, -16
    ld c, 020h
_:  ld (TopRowLeftOrRight), a
    ld a, c
    ld (IncrementRowXOrNot1), a
    ld a, (ix+OFFSET_Y)                                         ; Point to the output
    add a, 31 - 8                                               ; We start at row 31
    ld e, a
    ld d, 160
    mlt de
    ld hl, (currDrawingBuffer)
    add hl, de
    add hl, de
    ld d, 0
    ld a, b
    add a, 15
    ld e, a
    add hl, de
    ld (startingPosition), hl
    ld hl, (_IYOffsets + TopLeftYTile)                           ; Y*MAP_SIZE+X, point to the map data
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, (_IYOffsets + TopLeftXTile)
    add hl, de
    add hl, hl                                                  ; Each tile is 2 bytes worth
    ld bc, mapAddress
    add hl, bc
    ld ix, (_IYOffsets + TopLeftYTile)
    ld a, 23
    ld (TempSP2), sp
    ld (TempSP3), sp
    ld sp, lcdWidth
DisplayEachRowLoop:
; Registers:
;   A   = height of tile/building
;   BC  = length of row tile
;   DE  = pointer to output
;   HL  = pointer to tile/black tile
;   A'  = row index
;   B'  = column index
;   DE' = x index tile
;   HL' = pointer to map data
;   IX  = y index tile
;   IY  = pointer to output
;   SP  = SCREEN_WIDTH

startingPosition = $+2                                          ; Here are the shadow registers active
    ld iy, 101
    ld bc, 8*320
    add iy, bc
    ld (startingPosition), iy
    bit 0, a
    jr nz, +_
TopRowLeftOrRight = $+2
    lea iy, iy+0
_:  ex af, af'
    ld a, 9
DisplayTile:
    ld b, a
    ld a, d
    or a, ixh
    jr nz, TileIsOutOfField
    ld a, e                                                     ; Check if one of the both indexes is more than the MAP_SIZE, which is $80
    or a, ixl
    add a, a
    jr c, TileIsOutOfField
CheckWhatTypeOfTileItIs:
    ld a, (hl)
    exx                                                         ; Here are the main registers active
    or a, a
    jp z, SkipDrawingOfTile
    ld c, a
    ld b, 7
    mlt bc
    ld hl, TilePointers-7
    add hl, bc
    ld de, (hl)                                                 ; Offset from the current position, if the tile/building has a height
    add iy, de
    inc hl
    inc hl
    inc hl
    ld a, (hl)                                                  ; Height of the tile
    inc hl
    ld hl, (hl)                                                 ; Pointer to the tile
    jr +_
TileIsOutOfField:
    exx
    ld hl, blackBuffer
    ld a, 1
_:  lea de, iy
    jp DrawTiles
ActuallyDisplayTile:
    add iy, sp
    lea de, iy-14
    ld c, 30
    ldir
_:  add iy, sp                                                  ; Display middle part of the building/tile
    lea de, iy-15
    ld c, 32
    ldir
    dec a
    jr nz, -_
    add iy, sp
    lea de, iy-14
    ld c, 30
    ldir
    add iy, sp
    lea de, iy-12
    ld c, 26
    ldir
    add iy, sp
    lea de, iy-10
    ld c, 22
    ldir
    add iy, sp
    lea de, iy-8
    ld c, 18
    ldir
    add iy, sp
    lea de, iy-6
    ld c, 14
    ldir
    add iy, sp
    lea de, iy-4
    ld c, 10
    ldir
    add iy, sp
    lea de, iy-2
    ld c, 6
    ldir
    add iy, sp
    lea de, iy-0
    ldi
    ldi
    ld de, 32-(320*16)
    jr +_
SkipDrawingOfTile:
    ld de, 32
_:  add iy, de
    exx
    inc de
    dec ix
    ld a, b
    ld bc, (-MAP_SIZE+1)*2
    add hl, bc
    dec a
    jp nz, DisplayTile
    ld bc, (MAP_SIZE*10-9)*2
    add hl, bc
    ex de, hl
    ld bc, -9
    add hl, bc
    ex de, hl
    lea ix, ix+9+1
    ex af, af'
    bit 0, a
IncrementRowXOrNot1:
    jr nz, +_
    inc de
    ld bc, (-MAP_SIZE+1)*2
    add hl, bc
    dec ix
_:  dec a
    jp nz, DisplayEachRowLoop
    ld de, (currDrawingBuffer)
    ld hl, _resources \.r2
    ld bc, _resources_width * _resources_height
    ldir
    ld hl, blackBuffer
    ld bc, 320*40+32
    ld a, 160
_:  ldir
    ex de, hl
    inc b
    add hl, bc
    ex de, hl
    ld c, 32+32
    dec b
    dec a
    jr nz, -_
    ld bc, 320*25+32
    ldir
TempSP2 = $+1
    ld sp, 0
DrawFieldEnd:

PuppetsEvents:
    ld a, (AmountOfPeople)
    or a, a
    ex af, af'
    ld ix, puppetStack
    ld iy, _IYOffsets
    ;ld hl, (_IYOffsets + TopLeftXTile)
    ;ld de, (_IYOffsets + TopLeftYTile)
    ;or a, a
    ;sbc hl, de
    ;ld (iy+0), hl
    ;add hl, de
    ;add hl, de
    ;ld (iy+3), hl
PuppetEventLoop:
    ex af, af'
    jr z, DisplaySelectedAreaBorder
    ex af, af'

; isoToScreenX(X_tile - X_1) <= 320
; isoToScreenY(Y_tile - Y_1) <= 240

; var posX = (x - y) * tileW;
; var posY = (x + y) * tileH / 2;

    or a, a
    sbc hl, hl
    ld l, (ix+puppetX)
    ld de, (iy+TopLeftXTile)
    sbc hl, de
    ld (iy+TempData2), hl                                                       ; X_tile - X_1
    add hl, de
    ld l, (ix+puppetX)
    ld de, (iy+TopLeftYTile)
    or a, a
    sbc hl, de
    ld (iy+TempData2+3), hl                                                     ; Y_tile - Y_1
    ex de, hl
    ld hl, (iy+TempData2)
    or a, a
    sbc hl, de
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, 0
    ld a, (variables+OFFSET_X)
    ld e, a
    add hl, de
    ld (iy+TempData2+6), hl
    ld hl, (iy+TempData2)
    ld de, (iy+TempData2+3)
    add hl, de
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, variables+OFFSET_Y
    ld a, (de)
    add a, l
    ld l, a
    ld h, 160
    mlt hl
    add hl, hl
    ld de, (iy+TempData2+6)
    add hl, de
    ld de, (31*320)+15
    add hl, de
    ld de, (currDrawingBuffer)
    add hl, de
    ld (hl), 255
    push hl
    pop de
    inc de
    ld bc, 20
    ldir
    

DontDrawPuppet:
    ; Event
    
    ex af, af'
    dec a
    lea ix, ix+9
    ex af, af'
    jr PuppetEventLoop
PuppetsEventsEnd:

DisplaySelectedAreaBorder:
    ld iy, _IYOffsets
    bit holdDownEnterKey, (iy+AoCEFlags1)
    jr z, DisplayCursor                                                 ; We didn't select an area
    ld a, (iy+SelectedAreaStartY)
    ld b, (iy+CursorY)
    cp a, b
    ex af, af'
    ld hl, (iy+SelectedAreaStartX)
    ld de, (iy+CursorX)
    or a, a
    sbc hl, de
    jr nz, DrawSelectedArea
    ex af, af'
    jr z, DisplayCursor
    jr +_
DrawSelectedArea:
    ex af, af'
_:  add hl, de
    jr nc, +_
    ex de, hl
_:  or a, a
    sbc hl, de
    inc hl
    sub a, b
    jr nc, +_
    neg
    ld b, (iy+SelectedAreaStartY)
_:  inc a
    ld c, a
    push bc                                                         ; Height
        push hl                                                     ; Width
            ld c, b
            push bc                                                 ; Y
                push de                                             ; X
                    call gfx_Rectangle_NoClip
                    ld iy, _IYOffsets
DisplayCursor:
                    ld l, (iy+CursorY)
                    push hl
                        ld hl, (iy+CursorX)
                        push hl
                            ld hl, _cursor \.r2
                            push hl
                                call gfx_TransparentSprite_NoClip
TempSP3 = $+1
    ld sp, 0
    ret
DisplayCursorEnd:

#IF $ - DrawField > 1024
.error "cursorImage data too large: ",$-DrawField," bytes!"
#ENDIF
    
endrelocate()

drawtiles_loc = $
relocate(mpShaData)

DrawTiles:
    ld bc, 2
    ldir
    add iy, sp
    lea de, iy-2
    ld c, 6
    ldir
    add iy, sp
    lea de, iy-4
    ld c, 10
    ldir
    add iy, sp
    lea de, iy-6
    ld c, 14
    ldir
    add iy, sp
    lea de, iy-8
    ld c, 18
    ldir
    add iy, sp
    lea de, iy-10
    ld c, 22
    ldir
    add iy, sp
    lea de, iy-12
    ld c, 26
    ldir
    jp ActuallyDisplayTile
DrawTilesEnd:

#IF $ - DrawTiles > 64
.error "mpShaData data too large: ",$-DrawTiles," bytes!"
#ENDIF

endrelocate()