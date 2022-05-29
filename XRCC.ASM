.model  tiny

.386p


.code
org     100h
Start:
        mov     ah,09h
        mov     dx,offset Intro
        int     21h

        mov     ah,09h
        mov     dx,offset Registered
        int     21h

        push    cs
        pop     es
        mov     di,80h
        xor     cx,cx
        mov     cl,byte ptr ds:[di]
        cmp     cl,0
        jnz     weiteragain
        push    cs
        pop     ds
        mov     dx,offset nOPARAM
        mov     ah,09h
        int     21h
        int     20h

Weiteragain:
        sub     cl,1
        mov     si,82h
        mov     di,offset filename
        rep     movsb
        xor     al,al
        stosb
;-----------MALLOC-------------------------------------------------
        mov     ah,4Ah
        mov     bx,340          ; 300*16 = 5-6 kb
        int     21h

        mov     ah,48h
        mov     bx,4096
        int     21h
        mov     word ptr cs:[AllocateMem],ax

;;----------BUG bei grossen COMs?---------------------
        mov     sp, $

        mov     ax,3D02h                ; r/w!
        mov     dx,offset Filename
        int     21h
;       cmp     ax,2
;       jnz     @cONTINUE               ; bug!
        jnc     @cONTINUE
@fOPEN:
        mov     ah,09h
        mov     dx,offset Open
        int     21h
        int     20h

@cONTINUE:
        mov     word ptr cs:[Fhandle],ax
        mov     bx,ax

        mov     ax,3F00h
        mov     ds,word ptr cs:[AllocateMem]
        mov     cx,65535
        mov     dx,100h
        int     21h
        jc      @fOPEN
        mov     word ptr cs:[FileSize],ax
        mov     ah,3Eh
        int     21h                             ; close

        cmp     word ptr ds:[100h],5A4Dh
        jz      eXE
        cmp     word ptr ds:[100h],4D5Ah
        jnz     @cOM
eXE:
        push    cs
        pop     ds
        mov     ah,09h
        mov     dx,offset NoEXE
        int     21h
        int     20h

@cOM:
        cmp     byte ptr ds:[100h],0FAh
        jz      @rCCFOUND
        push    cs
        pop     ds
        mov     dx,offset NotFound
        mov     ah,09h
        int     21h
        int     20h

@rCCFOUND:
        mov     ax,3521h
        int     21h
        mov     word ptr cs:[Oldint21+2],es
        mov     word ptr cs:[Oldint21],bx

        push    cs
        pop     ds
        mov     ah, 9
        mov     dx, offset alive
        int     21h

        mov     ax,2501h
        mov     dx,offset Newint1
        int     21h

        mov     ax,2521h
        mov     dx,offset Newint21
        int     21h

        mov     ax,25D0h
        mov     dx,offset Newint3
        int     21h

        mov     ax,25D1h
        mov     dx,offset NewintD1
        int     21h

        mov     ax,cs
        mov     es,ax
        xor     ax,ax
        mov     ds,ax
        xor     si,si
        mov     di,offset buffer
        mov     cx,256
        rep     movsd

        cli
        xor     eax,eax
        mov     dr6,eax
        mov     ax,word ptr cs:[AllocateMem]
        shl     eax,4
        add     eax,100h        ; brk point
        mov     dr0,eax
        xor     eax,eax
        or      eax,1           ; 100h exec
        or      eax,65536
        mov     dr7,eax
        sti

        push    cs
        pop     ds
        mov     ah,09h
        mov     dx,offset breakpoint
        int     21h

        mov     ds,word ptr cs:[AllocateMem]
        xor     ax,ax
        xor     bx,bx
        xor     cx,cx
        cwd
        push    ds
        pop     es
        push    ds
        pop     ss
        push    ds
        push    100h
        retf

; --=====[INt hANDlER]=====----------------------------------------------
Newint21 proc
        cmp     ah,30h
        jnz     @cALLOLD
        pusha
        push    es

        mov     bx,sp
        add     bx,10h
        add     bx,2
        mov     di,word ptr ss:[bx]
        mov     es,word ptr ss:[bx+2]
        cmp     word ptr es:[di],023Ch
        jnz     @cALLOLD2
        cmp     word ptr cs:[Counter],0
        jnz     @cALLOLD2

        xor     di,di
        mov     es,word ptr cs:[AllocateMem]
        mov     cx,65535

@sEARCH5:
        cmp     word ptr es:[di],0C93Bh
        jz      @paTCH
        inc     di
lOOP    @sEARCH5

        jmp     noPatch

@paTCH:
        mov     word ptr cs:[Hard],1
        mov     word ptr cs:[FoundIt2],di
        mov     word ptr es:[di],0D1CDh

@iNCIT:
        inc     word ptr cs:[Counter]

@cALLOLD2:
        pop     es
        popa
@cALLOLD:
        jmp     dword ptr cs:[Oldint21]
Newint21 endp


; --=====[INt hANDlER]=====----------------------------------------------
NewintD1 proc
        push    es
        push    ds
        pusha

        mov     es,word ptr cs:[AllocateMem]
        mov     di,word ptr cs:[FoundIt2]
        mov     byte ptr es:[di+2],0EBh

        xor     eax,eax
        mov     ax,cs
        shl     eax,4
        xor     ebx,ebx
        add     bx,offset buffer
        add     eax,ebx
        mov     dword ptr cs:idt_ptr+2,eax
        lidt    fword ptr cs:idt_ptr
        popa
        pop     ds
        pop     es
        iret
NewintD1 endp

; --=====[INt hANDlER]=====----------------------------------------------
Newint3 proc
        xor     ax,ax
        mov     es,ax
        push    cs
        pop     ds
        mov     si,offset Buffer
        xor     di,di
        mov     cx,256*4
        rep     movsb

        mov     ds,word ptr cs:[Oldint21+2]
        mov     dx,word ptr cs:[Oldint21]
        mov     ax,2521h
        int     21h

lidt fword ptr cs:old_idt

        push    cs
        pop     ds
        mov     ax,3C00h
        xor     cx,cx
        mov     dx,offset Filename
        int     21h
        mov     bx,ax

        mov     ax,4000h
        mov     ds,word ptr cs:[AllocateMem]
        mov     dx,100h
        mov     cx,word ptr cs:[FileSize]
        sub     cx,250
        cmp     word ptr cs:[Hard],1
        jnz     @nOHARD
        sub     cx,350

@nOHARD:
        int     21h

        mov     ah,3Eh
        int     21h
        push    cs
        pop     ds
        mov     dx,offset Write
        mov     ah,09h
        int     21h
        mov     dx,offset Write2
        mov     ah,09h
        int     21h
        int     20h
Newint3 endp

; --=====[INt hANDlER]=====----------------------------------------------
Newint1 proc
        push    ds
        push    cx
        push    di

        push    ax
        xor     eax,eax
        mov     dr7,eax
        mov     dr6,eax
        mov     dr0,eax
        pop     ax

        mov     ds,word ptr cs:[AllocateMem]
        mov     cx,65535
        mov     di,100h
@sEARCH:
        cmp     word ptr ds:[di],48C3h
        jz      @pATCHIT
        inc     di
lOOP    @sEARCH
        jmp     noPatch
@pATCHIT:
        mov     word ptr cs:[FoundIt],di
        mov     word ptr ds:[di],0D0CDh
        pop     di
        pop     cx
        pop     ds
        iret
Newint1 endp

noPatch:
        mov     ah, 9
        mov     dx, offset NotFound
        push    cs
        pop     ds
        int     21h
        int     20h

; --=====[INt hANDlER]=====----------------------------------------------
        Filename db "            ",0
        Liest   db " Wer das liest ist doof!            ",0ah,0dh,"$"
        Intro   db "-= XRCC 0.667á (C) 1996! by RAND0M^xADI^nME^iF =-",0ah,0dh,"$"
        AllocateMem dw  ?
        Fhandle dw ?
        Alive   db  "   þ=-> Setting environment!", 13, 10,"$"
        NotFound db "   þ!-> No known RCC version found! ",0ah,0dh,7,"$"
        BreakPoint db "   þ=-> Setting enhanced breakpoint ",0ah,0dh,"$"
        Write   db "   þ=-> File unpacked?              ",0ah,0dh,"$"
        Write2  db "   þ=-> written in a half hour to show you rcc's power ;)",0ah,0dh,"$"
        nOPARAM db "   þ>-> Syntax : XRCC <filename>    ",0ah,0dh,"$"
        NoEXE   db "   þ>-> Hey this is an EXE file     ",0ah,0dh,7,"$"
        Open    db "   þ>-> Can't open this file        ",0ah,0dh,7,"$"
        Registered db "   Registered to: ROSE SWE, RalphRoth@gmx.de ",0ah,0dh,0ah,0dh,"$"
        FileSize dw ?
        FoundIt dw ?
        buffer  dd 256 dup (0)
        idt_ptr dw 3ffh,0,0,0
        old_idt dw 3ffh,0,0,0
        Oldint21 dd ?
        Counter dw 0
        FoundIt2 dw ?
        Hard    dw ?

End     Start
