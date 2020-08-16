;---------------------------------------------------------------------------------------------------------------------------
;Programa em assembly que resolve, utilizando a pilha da memória, o problema das Torres de Hanoi. Instruções de compilação:
;   Compilar:  nasm -f elf32 hanoi.asm 
;       Link:      gcc -m32 -o hanoi hanoi.o
;           Execução:  ./hanoi
;---------------------------------------------------------------------------------------------------------------------------

section .data
    output_format: db "Ação #%d. Torre %d para Torre %d", 10, 0   ;formato  de saída do printf + quebra de linha e '\0'
    initial_message: db "Escolha o numero de discos desejados. Max = 6: ", 0 ;mensagem inicial para escolha de discos e '\0'
    input_format: db "%d", 0 ; formato de entrada

section .bss
    vector: resw 127 ; aloca espaço na memória para registrar as jogadas. No pior caso (6 discos) possui 63 posições
                     ; Como tenho que registrar de onde ele vem  então 2*63: 126 + o -1 do final do vetor para indicar que chegou a ação final

section .text
    extern printf
    extern scanf
    global main

%macro caller 0             
    push ebp                ; Seguindo a convenção para chamadas. Empilha ebp na pilha da memória. Estrutura antiga é salva, para podermos inicializar uma nova estrutura.
    mov ebp, esp            ; O registrador ebp recebe esp. Assim formando uma nova estrutura na pilha.
%endmacro

%macro uncaller 0
    mov esp, ebp        ; Seguindo a convenção para chamadas. esp recebe ebp, assim começando o return
    pop ebp             ; Desempilha ebp
    ret                 ; retorna da subrotina
%endmacro
;-------------------------------------------------
;Funcionamento principal do algoritmo:
; Main: Contém as instruções que serão utilizadas
;-------------------------------------------------
main:
    caller

;----------------------------------------------------------
;   _inicio : Inicializa o necessário para o programa
;funcionar. Imprime na tela mensagens iniciais, recebe
;informações do usuário e previne que um número indeseja-
;do de discos seja inserido. Também inicializa registrado-
;res que serão utilizados e salva informações que serão
;importantes para a resolução como a inicialização de 
;cada torre
;
;   Torre Origem = 1
;   Torre Auxiliar = 2
;   Torre Destino= 3
;   EAX = Armazena o número de discos   
;-----------------------------------------------------------
_inicio:
    push initial_message    ; Empilha  mensagem inicial para utilizar printf
    call printf             ; Chama printf
    add esp, 4              ; Atualiza topo da pilha

    lea eax, [ebp-4]        ; Move o endereço de ebp-4 para eax. Coleta o endereço em que vai ser gravado
    push eax                ; Salva o endereço a ser gravado.
    push input_format       ; Empilha o formato da entrada para receber número de discos do usuário
    call scanf              ; Chama scanf
    add  esp, 8             ; Atualiza topo da pilha

    mov eax, [ebp-4]        ; Carrega em eax o valor que foi pedido ao usuário. O número de discos

    cmp eax, 6              ; Confere se o usuário digitou número de discos maior que 6
    jg  _inicio

    cmp eax, 1
    jl  _inicio             ; Confere se o usuário digitou número de discos menor que 1

    xor ecx, ecx            ; ecx = 0
    push 2                  ; Empilha torre auxiliar
    push 3                  ; Empilha torre destino
    push 1                  ; Empilha torre origem
    push eax                ; Empilha numero de discos

    call _Hanoi             ; Chama subrotina recursiva para resolver problema
    add esp, 16             ; Atualiza topo da pilha

    mov dword [vector+ecx], -1    ;   posição final recebe -1
    add ecx, 4              ; Percorrimento do vetor. ECX é utilizado como contador para o vetor
    jmp _empilhaVector      ; Chama a subrotina que joga o vetor para pilha

;-------------------------------------------------------------------------------------------
;   Hanoi: subrotina para a resolução do problema.
;É aqui que a "magia" acontece. Utiliza a pilha da
;memória para resolver o problema. Código em python
;com o algoritmo de resolução utilizado:
;
;   def TorreDeHanoi(n_discos , torre_origem, torre_destino, torre_aux): 
;       if n_discos == 1: 
;           print("Move disco 1 da Torre",torre_origem,"para Torre",torre_destino)
;           return
;       TorreDeHanoi(n_discos-1, torre_origem, torre_aux, torre_destino) 
;       print("Move disco",n_discos,"da Torre",torre_origem,"para Torre",torre_destino) 
;       TorreDeHanoi(n_discos-1, torre_aux, torre_destino, torre_origem) 
;
;-------------------------------------------------------------------------------------------
    _Hanoi:
        caller            ; Hanoi(NUM_DISCOS[+8], ORIGEM[+12], DESTINO[+16], AUX[+20]) -> PILHA | Estrutura antiga é salva

        cmp dword[ebp+8], 1 ; Confere se o número de discos é igual a 1
        jne _n_maior        ; Caso seja maior que 1 então faz a recursão

        call _escreveVetor  ; Caso não seja chama subrotina _escreveVetor -> print("Move disco 1 da Torre",torre_origem,"para Torre",torre_destino)
        
        uncaller

        _n_maior:
            mov eax, [ebp+8] ; eax recebe o número de discos
            dec eax          ; decrementa o número de discos

            ;TorreDeHanoi(n_discos-1, torre_origem, torre_aux, torre_destino)
            push dword[ebp+16]    ; Empilha torre destin
            push dword[ebp+20]    ; Empilha torre auxiliar
            push dword[ebp+12]    ; Empilha torre origem
            push eax         ; Empilha o novo número de discos (N-1)
            call _Hanoi       ; chamada recursiva
            add esp, 16      ; Atualiza topo da pilha após chamada de subrotina

            call _escreveVetor ; Chama subrotina de _escreveVetor --> print("Move disco",n_discos,"da Torre",torre_origem,"para Torre",torre_destino)

            mov eax, [ebp+8] ; eax recebe o número de discos
            dec eax          ; decrementa o número de discos
            
            ;TorreDeHanoi(n_discos-1, torre_aux, torre_destino, torre_origem)
            push dword[ebp+12]    ; Empilha torre origem
            push dword[ebp+16]    ; Empilha torre destino
            push dword[ebp+20]    ; Empilha torre auxiliar
            push eax         ; Empilha novo numero de discos (N-1)
            call _Hanoi       ; Chamada recursiva
            add esp, 16      ; Atualiza topo da pilha após chamada de subrotina

            uncaller
    
    _escreveVetor:
        mov eax, [ebp+12]    ; eax recebe torre de origem
        mov [vector+ecx], eax; escreve torre de origem no vetor
        add ecx, 4           ; atualiza índice do vetor

        mov eax, [ebp+16]    ; eax recebe torre de destino
        mov [vector+ecx], eax; escreve torre de destino em vetor
        add ecx, 4           ; atualiza índice do vetor

        ret                  ; retorna da subrotina

    _empilhaVector:
        cmp ecx, -4          ; confere se o indíce do vetor é igual a -4 -> vector[i] em que i = -1
        je _invisivel
        push dword[vector+ecx]    ; caso não seja diminui até que seja
        sub ecx, 4                ; i--
        jmp _empilhaVector

    _invisivel:
        mov ecx, 1          ; Ecx recebe torre de origem
    _imprime_resultado:
        cmp dword[esp], -1       ; confere se chegou ao final, sinalizado por -1, se sim vai pro final
        je _final

        push ecx            ; Envia torre salva em eecx
        push output_format  ; Salva formato da saida
        call printf         ; imprime a saída

        mov ecx, [esp+4]    ; ecx recebe o valor contido no próximo endereço de esp, que representa a torre em questão.
        inc ecx             ; incrementa o ecx
        add esp, 16         ; Atualiza topo da pilha

        jmp _imprime_resultado ;Continua até chegar em -1

    _final:
        xor eax, eax ;Limpa eax. eax = 0
        uncaller



