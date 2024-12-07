ORG 100H
.MODEL SMALL
.STACK 100H              
            
                     
.data segment   
;this is the cipherKey, which should be taken as input at the start of the code 

buffer1 DB 0FFh, 010h

cipherKey DB 256 dup(00)          
cipherKeyPrompt DB "Enter a 16 character string (cipher key): $"   

buffer DB 11h, 10h                                                                                      
                                                                                      
;this is the roundKey, which should be taken as input at the start of the code
roundKey DB 16 dup(00)
roundKeyPrompt DB "   Enter a 16 character string (round key): $"  

cipherKeyOutput DB "     The encrypted text is:   $"



;variable to store the round number
roundCounter DB 00h

;variable that represents the decimal value 4
four DB 100b

;this is the RCON table, but reduced to 1 dimension
RCON DB 001h, 002h, 004h, 008h, 010h, 020h, 040h, 080h, 01bh, 036h

;this is the matrix required in the MixColumns procedure 
galoisFieldMatrix DB 002h, 003h, 001h, 001h
                  DB 001h, 002h, 003h, 001h
                  DB 001h, 001h, 002h, 003h
                  DB 003h, 001h, 001h, 002h

;this is the SBOX used in some operations, it is hardcoded 
SBOX DB 063h, 07Ch, 077h, 07Bh, 0F2h, 06Bh, 06Fh, 0C5h, 030h, 001h, 067h, 02Bh, 0FEh, 0D7h, 0ABh, 076h
     DB 0CAh, 082h, 0C9h, 07Dh, 0FAh, 059h, 047h, 0F0h, 0ADh, 0D4h, 0A2h, 0AFh, 09Ch, 0A4h, 072h, 0C0h
     DB 0B7h, 0FDh, 093h, 026h, 036h, 03Fh, 0F7h, 0CCh, 034h, 0A5h, 0E5h, 0F1h, 071h, 0D8h, 031h, 015h
     DB 004h, 0C7h, 023h, 0C3h, 018h, 096h, 005h, 09Ah, 007h, 012h, 080h, 0E2h, 0EBh, 027h, 0B2h, 075h
     DB 009h, 083h, 02Ch, 01Ah, 01Bh, 06Eh, 05Ah, 0A0h, 052h, 03Bh, 0D6h, 0B3h, 029h, 0E3h, 02Fh, 084h
     DB 053h, 0D1h, 000h, 0EDh, 020h, 0FCh, 0B1h, 05Bh, 06Ah, 0CBh, 0BEh, 039h, 04Ah, 04Ch, 058h, 0CFh
     DB 0D0h, 0EFh, 0AAh, 0FBh, 043h, 04Dh, 033h, 085h, 045h, 0F9h, 002h, 07Fh, 050h, 03Ch, 09Fh, 0A8h
     DB 051h, 0A3h, 040h, 08Fh, 092h, 09Dh, 038h, 0F5h, 0BCh, 0B6h, 0DAh, 021h, 010h, 0FFh, 0F3h, 0D2h
     DB 0CDh, 00Ch, 013h, 0ECh, 05Fh, 097h, 044h, 017h, 0C4h, 0A7h, 07Eh, 03Dh, 064h, 05Dh, 019h, 073h
     DB 060h, 081h, 04Fh, 0DCh, 022h, 02Ah, 090h, 088h, 046h, 0EEh, 0B8h, 014h, 0DEh, 05Eh, 00Bh, 0DBh
     DB 0E0h, 032h, 03Ah, 00Ah, 049h, 006h, 024h, 05Ch, 0C2h, 0D3h, 0ACh, 062h, 091h, 095h, 0E4h, 079h
     DB 0E7h, 0C8h, 037h, 06Dh, 08Dh, 0D5h, 04Eh, 0A9h, 06Ch, 056h, 0F4h, 0EAh, 065h, 07Ah, 0Aeh, 008h
     DB 0BAh, 078h, 025h, 02Eh, 01Ch, 0A6h, 0B4h, 0C6h, 0E8h, 0DDh, 074h, 01Fh, 04Bh, 0BDh, 08Bh, 08Ah
     DB 070h, 03Eh, 0B5h, 066h, 048h, 003h, 0F6h, 00Eh, 061h, 035h, 057h, 0B9h, 086h, 0C1h, 01Dh, 09Eh
     DB 0E1h, 0F8h, 098h, 011h, 069h, 0D9h, 08Eh, 094h, 09Bh, 01Eh, 087h, 0E9h, 0CEh, 055h, 028h, 0DFh
     DB 08Ch, 0A1h, 089h, 00Dh, 0BFh, 0E6h, 042h, 068h, 041h, 099h, 02Dh, 00Fh, 0B0h, 054h, 0BBh, 016h  
     
     


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code segment    
main proc                        
    CALL read   
    MOV cipherKey[16], '$'   
    MOV SI, 17
    removeCharLoop:  
        DEC SI
        CMP cipherKey[SI], 00Dh
        JNZ removeCharLoop
        MOV cipherKey[SI], 000h
    
    MOV SI, 17  
    removeCharLoop1:  
        DEC SI
        CMP roundKey[SI], 00Dh
        JNZ removeCharLoop1
        MOV roundKey[SI], 000h
        
    ;CALL output
    MOV AX, @data                   ;moving the head of the data segment to AX
    MOV DS, AX                      ;moving this value to DS
    MOV SI, 0                       ;setting SI to 0
    CALL addRoundKey                ;calling the first run of addRoundKey  
    CALL keySchedule                ;calling the first run of keySchedule     
 
cycle:                      
    INC roundCounter                ;incrementing the round counter
    MOV DI, 010h                    ;setting DI to 16, since this indicator is needed for the subBytes procedure     
    CALL subBytes                   ;calling subBytes procedure
    CALL shiftRows                  ;calling shiftRows procedure
    CALL mixColumns                 ;calling mixColumns procedure
    
    CALL addRoundKey                ;calling addRoundKey procedure
    CALL keySchedule                ;calling keySchedule procedure
    

    CMP roundCounter, 9             ;checking if 9 cycles have been completed and if it is then we don't do mixColumns
    JNZ cycle                       ;repeating cycle if they are not completed
    
    MOV DI, 010h                    ;setting DI to 16 again     
    CALL subBytes                   ;calling subBytes procedure for the tenth cycle
    CALL shiftRows                  ;calling shiftRows procedure for the tenth cycle
    CALL addRoundKey                ;calling the addRoundKey procedure for the tenth cycle 
    
    CALL output
              
    HLT                             ;halting program                     
main endp    








read PROC                                       
    
    ; Takes:
    ; No inputs
    ; Uses:
    ; "DX": Points to the message to be displayed for input
    ; "AH": System call to display prompt and read input
    ; Modifies:
    ; "cipherKey" and "roundKey": Stores user-provided input
    
    ; Printing the input prompt for the cipher key
    MOV AH, 9
    MOV DX, OFFSET cipherKeyPrompt 
    INT 21H
    
    ; Reading the input
    MOV AH, 0AH
    LEA DX, cipherKey-2  
    MOV cipherKey, 17
    INT 21H  
                 
                              
    ; Printing the input prompt for the round key                             
    MOV AH, 9
    MOV DX, OFFSET roundKeyPrompt 
    INT 21H
    
    ; Reading the input
    MOV AH, 0AH
    LEA DX, roundKey-2  
    MOV roundKey, 17
    INT 21H
    RET 
    
read ENDP     

output PROC                
    
    ; Takes:
    ; No inputs
    ; Uses:
    ; "DX": Points to the message and data to be displayed
    ; "AH": System call to display text
    ; Returns:
    ; No registers or memory modified
    
    MOV AH, 9
    MOV DX, OFFSET cipherKeyOutput 
    INT 21H 
    
    MOV AH, 9
    MOV DX, OFFSET cipherKey 
    INT 21H
    
    RET
output ENDP




subBytes proc          
    
    ; Takes:
    ; "DI": Determines if it’s called by keySchedule (DI=16) or regular use (DI=0)
    ; "SI": Tracks the index of the cipherKey or roundKey
    ; Uses:
    ; "AX": Temporary storage for current byte index
    ; "AL": Stores current byte being processed
    ; Returns:
    ; "cipherKey" or "roundKey": Updated with the substituted values
    ; Modifies:
    ; "DI" and "SI": For navigation of SBOX and respective data arrays
    
    CMP DI, 010h                    ;checking if this call was from the keySchedule procedure or if it is a regular subBytes procedure
    JNZ subBytesforKeySchedule      ;jumping to subBytesForKeySchedule if it is from the keySchedule procedure
    
    MOV SI, 0                       ;setting SI to 0 in case it was not
     
subBytesForCipherKeyLoop:          
    MOV AX, 0                       ;setting AX to 0 since it was affected in previous loops
    MOV AL, cipherKey[SI]           ;moving the cipherKey value we are currently at into AL
    MOV DI, AX                      ;setting DI to the value of AX, which represents the required cell in the SBOX
    MOV AL, SBOX[DI]                ;getting the value required from the SBOX and putting it in AL
    MOV cipherKey[SI], AL           ;moving the value from the AL to its position in the cipherKey
    INC SI                          ;incrementing the loop counter
    CMP SI, 16                      ;checking if we finished all of the elements (16 elements)
    JNZ subBytesForCipherKeyLoop    ;repeating one more cycle if not           
    RET                             ;returning from the procedure
    
subBytesForKeySchedule:
    MOV AX, 0                       ;setting AX to 0
    MOV AL, roundKey[DI]            ;setting AL to the roundKey value whose index is specified in DI
    PUSH SI                         ;saving the value of SI by pushing it to the stack
    MOV SI, AX                      ;setting SI to the value of AX, which represents the required cell in the SBOX
    MOV AL, SBOX[SI]                ;getting the call required from the SBOX and putting it in AL
    POP SI                          ;restoring the initial value of SI
    MOV roundKey[DI], AL            ;setting the position in roundKey specified by DI to its respective subByte value
    RET                             ;returning from the procedure    
subBytes endp


shiftRows proc     
    
    ; Takes:
    ; No inputs (modifies the cipherKey directly)
    ; Uses:
    ; "SI": Tracks rows being shifted
    ; Returns:
    ; "cipherKey": Updated with shifted rows
    ; Modifies:
    ; "cipherKey" and "SI"
    
    MOV AX, 4                       ;set the rotateWord's starting index to 4
    CALL rotateWord                 ;rotate once

    MOV AX, 8                       ;set the rotateWord's starting index to 8
    CALL rotateWord                 ;rotate once
    MOV AX, 8                       ;reset the rotateWord's starting index to 8 again
    CALL rotateWord                 ;rotate once (second time)

    MOV AX, 12                      ;set the rotateWord's starting index to 12
    CALL rotateWord                 ;rotate once
    MOV AX, 12                      ;reset the rotateWord's starting index to 12 again
    CALL rotateWord                 ;rotate once (second time)
    MOV AX, 12                      ;reset the rotateWord's starting index to 12 again
    CALL rotateWord                 ;rotate once (third time)
    RET                             ;returning from the procedure        
shiftRows endp        

rotateWord proc     
    
    ; Takes:
    ; "AX": Specifies the starting index in the cipherKey array to be rotated
    ; Uses:
    ; "DI": Tracks the position within the cipherKey array
    ; "AL, AH": Temporary storage for rotation
    ; Returns:
    ; "cipherKey[AX:AX+3]": Rotated word (4 bytes in the cipherKey array)
    ; Modifies:
    ; "DI", "AL", "AH"
    
    MOV DI, AX                      ;set DI to the starting point in the cipherKey array                  
    
    MOV AL, cipherKey[DI]           ;save the leftmost byte to AL, because it will be the last element after rotation 
    
    MOV AH, cipherKey[DI+1]         ;move DI + i to AH
    MOV cipherKey[DI], AH           ;and then move AH to cipherKey[DI], which basically moves the element at i+1 to i 
    
    MOV AH, cipherKey[DI+2]         ;do this for all i from 1 to 3, so here is i = 2
    MOV cipherKey[DI+1], AH   
    
    MOV AH, cipherKey[DI+3]         ;here i = 3
    MOV cipherKey[DI+2], AH       
    
    MOV cipherKey[DI+3], AL         ;now the last element will be the original first element, so retrieve it from AL
    RET                             ;returning from the procedure    
rotateWord endp


mixColumns proc   
    
    ; Takes:
    ; No inputs
    ; Uses:
    ; "SI, DI": Loop indices for rows and columns
    ; "CX": Temporary accumulator for new column values
    ; Returns:
    ; "cipherKey": Updated columns after mixing
    ; Modifies:
    ; "SI", "DI", "CX", "AX", "cipherKey"    
     
    MOV SI, 0                       ;setting SI to 0
    MOV DI, 0                       ;setting DI to 0
    MOV CX, 0                       ;setting CX to 0
matrixMultiplicationProcedureLoop:
    PUSH SI                         ;saving the value of SI in the stack
    PUSH DI                         ;saving the value of DI in the stack
    CALL matrixMultiplication       ;calling the matrixMultiplication procedure
    POP DI                          ;restoring the original value of DI from the stack
    POP SI                          ;restoring the original value of SI from the stack
    PUSH CX                         ;saving the new keyCipher[SI][DI] value in the stack
    INC DI                          ;incrementing DI
    CMP DI, 4                       ;checking if we finished 4 sub-cycles
    JNZ matrixMultiplicationProcedureLoop   ;repeating another sub-cycle if not
    MOV DI, 0                       ;setting DI to 0
    INC SI                          ;incrementing SI
    CMP SI, 4                       ;checking if we finished 4 cycles
    JNZ matrixMultiplicationProcedureLoop   ;repeating the cycle if not
   
    MOV SI, 010h                    ;setting SI to sixteen
changingCipherKeyLoop:
    DEC SI                          ;decrementing SI
    POP AX                          ;popping from the stack into AX
    MOV cipherKey[SI], AL           ;moving the value in AL to its correct position in the cipherKey table
    CMP SI, 0                       ;checking if SI has become 0
    JNZ changingCipherKeyLoop       ;repeating the cycle if not
    RET                             ;returning from the procedure
    
mixColumns endp
      
      
matrixMultiplication proc 
    
    ; Takes:
    ; No inputs
    ; Uses:
    ; "SI, DI, DL": Indices for rows, columns, and intermediate calculations
    ; "AL, BL, CL": Temporary storage for values and accumulators
    ; Returns:
    ; "CL": Result of the multiplication
    ; Modifies:
    ; "AX, DX, CX", "SI", "DI", "cipherKey", "galoisFieldMatrix"    
      
MOV CX, 0                           ;setting CX to 0
MOV DX, 0                           ;setting DX to 0
        
matrixMultiplicationLoop:           
    MOV AX, SI                      ;setting AX to the SI value
    MUL four                        ;multiplying this value by 4
    ADD AL, DL                      ;adding the value in DL to this value
    PUSH SI                         ;saving the value of SI to the stack
    MOV SI, AX                      ;setting SI to AX, which now contains the position of the cipherKey required
    MOV AL, DL                      ;setting AL to the value in DL
    MUL four                        ;multiplying that by 4
    ADD AX, DI                      ;adding  the value in DI to this value
    PUSH DI                         ;saving the value of DI to the stack
    MOV DI, AX                      ;setting DI to AX, which now contains the position of the galoisFieldMatrix value that is required
    MOV AL, cipherKey[DI]           ;moving the cipherKey value to AL
    MOV BL, galoisFieldMatrix[SI]   ;moving the galoisFieldMatrix value to BL
    CMP BL, 1                       ;checking if the galoisFieldMatrix value is 1
    JZ addToCL                      ;if it is, just XOR it with the accumulator, which is CX in the code
    CMP BL, 3                       ;if not, check if the value is 3
    JNZ skipXOR                     ;if it is not, then skip the extra XOR step resulting from the formula for XORing a binary number with 3
    XOR CL, AL                      ;proceeding with the conditional XOR
skipXOR:    
    SAL AL, 1                       ;shifting the cipherKey value once to the left, which is dividing by 2 
    JNC addToCL                     ;if the removed bit from the left was a 0, then add (XOR) the new value to the accumulator 
    XOR AL, 00011011b               ;if not, then proceed with the conditional XOR
addToCL:
    XOR CL, AL                      ;adding the value to the accumulator by XORing it since operations are done assuming the numbers are binary
    POP DI                          ;restoring the initial value of DI
    POP SI                          ;restoring the initial value of SI
    INC DL                          ;incrementing the value in DL, which helps in obtaining the correct row and column values
    CMP DL, 4                       ;checking if we did 4 cycles
    JNZ matrixMultiplicationLoop    ;doing another cycle if not
    RET                             ;returning from the procedure    
matrixMultiplication endp
  
  

   
   
addRoundKey proc     
    
    ; Takes:
    ; No inputs
    ; Uses:
    ; "SI": Loop index for iterating through cipherKey and roundKey
    ; "AL": Temporary storage for XOR operation
    ; Returns:
    ; "cipherKey": Updated with XORed values
    ; Modifies:
    ; "SI", "AL", "cipherKey"    
    
    MOV SI, 0                       ;setting SI to 0
addRoundKeyLoop:
    MOV AL, cipherKey[SI]           ;moving the cipherKey value to AL
    XOR AL, roundKey[SI]            ;adding (XOR) the roundKey value to its respective cipherKey value
    MOV cipherKey[SI], AL           ;moving this new value back to its correct position in the cipherKey
    INC SI                          ;incrementing SI (which acts as the loop counter)
    CMP SI, 16                      ;checking if we finished 16 cycles
    JNZ addRoundKeyLoop             ;repeating the loop again if not
    RET                             ;returning from the procedure    
addRoundKey endp
       
       
keySchedule PROC     
    ; Takes:
    ; No explicit inputs
    ; Uses:
    ; "SI, DI": Loop counters
    ; "AL, CL, CH, DL, DH": Temporary storage for operations
    ; Returns:
    ; "roundKey": Updated with new key values
    ; Modifies:
    ; "SI", "DI", "roundKey"    

    MOV SI, 3               ; initialize SI to point to the last column in the roundKey (index 3)
    MOV CL, roundKey[3]     ; save roundKey[3] to CL
    MOV CH, roundKey[7]     ; save roundKey[7] to CH
    MOV DL, roundKey[11]    ; save roundKey[11] to DL
    MOV DH, roundKey[15]    ; save roundKey[15] to DH

loop1:                      ; rotate and substitute the bytes in the last column
    ADD SI, 100b            ; increment SI by 4 (move to the next byte in the column)
    MOV AH, roundKey[SI]    ; save the current byte in AH
    SUB SI, 100b            ; decrement SI by 4 (move back to the original position)
    MOV roundKey[SI], AH    ; overwrite the original byte with the next one in the column
    MOV DI, SI              ; set DI to SI for substitution
    CALL subBytes           ; perform byte substitution using the subBytes procedure
    ADD SI, 100b            ; move to the next byte in the column
    CMP SI, 15              ; check if we have processed all bytes in the last column
    JNZ loop1               ; repeat the loop if not finished

    MOV roundKey[15], CL    ; restore the first byte of the column to its new position (from CL)
    MOV DI, 15              ; set DI to the index of the last byte in the column
    CALL subBytes           ; substitute this byte using the subBytes procedure

    MOV AX, 0               ; clear AX
    MOV AL, roundCounter    ; load the roundCounter value into AL
    MOV SI, AX              ; set SI to the roundCounter value
    MOV AL, roundKey[3]     ; load the first byte of the last column into AL
    XOR AL, RCON[SI]        ; XOR it with the corresponding RCON value
    MOV roundKey[3], AL     ; store the result back in roundKey[3]

    ; XOR each word in the first column with the corresponding value from the previous column
    MOV AL, roundKey[0]     ; load roundKey[0] into AL
    XOR AL, roundKey[3]     ; XOR it with roundKey[3]
    MOV roundKey[0], AL     ; store the result in roundKey[0]

    MOV AL, roundKey[4]     ; load roundKey[4] into AL
    XOR AL, roundKey[7]     ; XOR it with roundKey[7]
    MOV roundKey[4], AL     ; store the result in roundKey[4]

    MOV AL, roundKey[8]     ; load roundKey[8] into AL
    XOR AL, roundKey[11]    ; XOR it with roundKey[11]
    MOV roundKey[8], AL     ; store the result in roundKey[8]

    MOV AL, roundKey[12]    ; load roundKey[12] into AL
    XOR AL, roundKey[15]    ; XOR it with roundKey[15]
    MOV roundKey[12], AL    ; store the result in roundKey[12]

    ; restore the original last column from the saved registers
    MOV roundKey[3], CL     ; restore roundKey[3] from CL
    MOV roundKey[7], CH     ; restore roundKey[7] from CH
    MOV roundKey[11], DL    ; restore roundKey[11] from DL
    MOV roundKey[15], DH    ; restore roundKey[15] from DH

    MOV DI, 1               ; set DI to 1 for the column-wise XORing loop
    MOV SI, 0               ; set SI to 0 for the first word in the roundKey

loop2:                      ; perform column-wise XORing
    PUSH SI                 ; save SI on the stack
    MOV AX, SI              ; load the current word index (SI) into AX
    MUL four                ; multiply by 4 to calculate the word offset
    MOV SI, AX              ; update SI to the byte offset
    MOV AX, 0               ; clear AX
    PUSH DI                 ; save DI on the stack
    ADD DI, SI              ; add the word offset to DI
    MOV AL, roundKey[DI]    ; load the current roundKey byte into AL
    XOR AL, roundKey[DI-1]  ; XOR it with the previous byte in the column
    MOV roundKey[DI], AL    ; store the result back in roundKey
    POP DI                  ; restore DI from the stack
    POP SI                  ; restore SI from the stack
    INC DI                  ; increment DI to process the next byte
    CMP DI, 4               ; check if we have processed all 4 bytes in the column
    JNZ loop2               ; repeat if not finished

    INC SI                  ; increment SI to process the next word
    MOV DI, 1               ; reset DI to 1 for the next column
    CMP SI, 4               ; check if we have processed all 4 words in the roundKey
    JNZ loop2               ; repeat if not finished

    RET                     ; return from the procedure
keySchedule ENDP
