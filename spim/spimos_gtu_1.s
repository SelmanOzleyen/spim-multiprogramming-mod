.data
# File names of the programs to load
filename: .asciiz "LinearSearch.s"
filename2: .asciiz "BinarySearch.s"
filename3: .asciiz "Collatz.s"
filename4: .asciiz "Palindrome.s"
# Kernel Prompt Message
prompt: .asciiz "Exitting Kernel...\n"
.text
.globl main
main:
############################################################################
# void init()
# init
# calls the syscalls to initialize the processes.
############################################################################
init:    
    
    # Calling init structure func
    jal _init_process_structure
        
    # a variable to be used on the final loop
    # t0 = -1
    li $t0,-1

    # fork is a critical region disable interrupts
    # fork() 
    li $v0,18
    syscall

    # If this is the child process branch
    
    # if(child) {branch();}
    beq $v0,$0,if_child
    # comes here after the if branch

    # fork()
    li $v0,18
    syscall

    # if(child) {branch();}
    beq $v0,$0,if_child2
    # comes here after the if branch

    # fork()
    li $v0,18
    syscall

    # if(child) {branch();}
    beq $v0,$0,if_child3
    # comes here after the if branch
    
    # fork()
    li $v0,18
    syscall

    # if(child) {branch();}
    beq $v0,$0,if_child4
    # comes here after the if branch

l1:
    # wait any child
    # wait()
    li $v0,20
    syscall

    # if there are no children left go to finised branch.
    # if(v0 == -1) {branch(finished);}
    li $t0,-1
    beq $t0,$v0,finished
    # else continue to the loop
j l1

finished:
    # the loop for waiting children is over.
    # propmt the user that the kernel is exitting
    # print("Exiting kernel...\n")
    li $v0,4
    la $a0,prompt
    syscall
    

    # Close the kernel
    # exit_process_syscall()
    li $v0,22
    syscall


if_child:
    # The process here is a child
    # Now call execv to load the new process
    # execv(filename)
    la $v0,19
    la $a0,filename
    syscall
    # if exev is successful this part wont be executed 

if_child2:
    # The process here is a child
    # Now call execv to load the new process
    # execv(filename)
    la $v0,19
    la $a0,filename2
    syscall
    # if exev is successful this part wont be executed 

if_child3:
    # The process here is a child
    # Now call execv to load the new process
    # execv(filename)
    la $v0,19
    la $a0,filename3
    syscall
    # if exev is successful this part wont be executed 
    
if_child4:
    # The process here is a child
    # Now call execv to load the new process
    # execv(filename)
    la $v0,19
    la $a0,filename4
    syscall
    # if exev is successful this part wont be executed 
    
############################# HANDLER PART ##################################
.data
# There can be at most process 100 process created in this OS
# These will be  arrays
.globl ready_processes
ready_processes: .word 0:100
.globl blocked_processes
blocked_processes: .word 0:100
# List of process process_states[i] will give state of process with id i
.globl process_states
process_states: .word 0:100
# kernel registers and the
.globl bl_size
bl_size: .word 0
.globl rl_size
rl_size: .word 0

.globl kernel_regs
kernel_regs: .word 0:16
.globl user_regs
user_regs: .word 0:17
# current process => $k1
# interrupt disabled => $k0
############################################################################
# void handle_interrupt()
# _handle_interrupt
# When an interrupt occurs, the os will execute this function.
# STATE_NO's : RUNNING = 1, BLOCKED = 2, READY = 3, TERMINATED = 4
# k0 -> interrupt enable bit
# k1 -> current pid
############################################################################
.text
.globl _handle_interrupt
_handle_interrupt:

    # Load the registers for kernel and PC
    
    ori $k0,$0,1 # disable interrupts


    # Do a context switch if the ready queue is not empty.
    # if(0 != ready_queue_size) branch;
    lw $s1,rl_size
    bne $0,$s1,ready_queue_not_empty
    # Label to return after branch
ready_queue_not_empty_return:
    
    # Load the process id in $k1
    la $v0,25
    # load_process($k1) syscall
    la $a0,0($k1)
    # will also enable interrupts
    syscall
    # end of execution

# There will be a context switch
ready_queue_not_empty:
    # save the $tx registers
    jal save_routine
    # pop the front of the queue and add the current process to the end of the queue
    # put the ready process list as argument
    la $a0,ready_processes
    # put the size of the queue
    lw $s1,rl_size
    la $a1,0($s1)
    jal pop_front
    # decrement the size of the queue after calling pop_front
    # $t0 = new current process
    la $t0,0($v0)

    # decrementing the size of the queue
    addi $s1,$s1,-1

    # the pointer remains the same
    # put the size of the queue
    la $a1,0($s1)
    # put the current process as argument
    la $a2,0($k1)
    # push the old process
    jal push_end


    # incrementing the size of the queue
    addi $s1,$s1,1

    # save the old process
    la $t3,0($k1)

    # set the new process
    # k1 = t0
    la $k1,0($t0)

    # update the status list
    # t1 = 4*k1
    sll $t1,$k1,2
    # t1 += status_arr
    # set $t4 as process_states pointer
    la $t4,process_states
    add $t1,$t1,$t4
    # t2 = RUNNING
    li $t2,1
    # status_arr[k0] = RUNNING
    sw $t2,0($t1)

    #t2 = READY
    li $t2,3
    #t1 = 4*t3 (old process)
    sll $t1,$t3,2    
    #t1 += status_arr
    la $t4,process_states
    add $t1,$t1,$t4
    # status_arr[t3] = READY
    sw $t2,0($t1)

    # restore the t registers
    jal restore_routine
    
    # return to the branch end
    j ready_queue_not_empty_return

#########################_handle_interrupt end##############################


###########################################################################
# int pop_front(int * arr, int size)
# pop_front
# $a0 the array to be popped
# $a1 the size of the array
# $v0 the popped value 
# A simple utility function to manipulate the process array
# after calling this the caller should decrement the size of its array
###########################################################################
pop_front:
    # save $ra to the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # Do the save routine
    jal save_routine

    # $v0 = arr[0]
    # The value to return is assigned
    lw $v0,0($a0)

    # Do a loop to shift the elements of the array
    # i = 0
    # while(size - 1 > i){
    #     arr[i] = arr[i+1]
    #     i++
    # }
    # $t2 = temp = size - 1
    addi $t2,$a1,-1
    # $t1 = arr + offset
    # $a1 = size
    # $t0 = i = 0
    li $t0,0
pop_loop:
    # $t3 = res =   i $t0 < size - 1 ($t2)
    slt $t3,$t0,$t2
    # if $t3 == 0 end the loop
    beq $0,$t3,pop_loop_end
    
    # set $t1 to arr + 4*i
    sll $t4,$t0,2
    add $t1,$a0,$t4

    # get the value of arr[i+1] and save it to $t4
    lw $t4,4($t1)
    # set arr[i] to $t4
    sw $t4,0($t1)

    # increment i ($ t0)
    addi $t0,$t0,1
    # i++
    # restart the loop
    j pop_loop

pop_loop_end:

    # Do the restore routine
    jal restore_routine
    # Restore routine end

    # restore $ra from the stack
    lw $ra, 0($sp)
    addi $sp, $sp,4
    # return to the caller
    jr $ra
######################## pop_front end ####################################    


###########################################################################
# void push_end(int * arr, int size, int item)
# push_end
# $a0 the array to be popped
# $a1 the size of the array
# $a2 the item to push 
# A simple utility function to manipulate the process array
# after calling this the caller should decrement the size of its array
###########################################################################
push_end:
    # save $t0
    addi $sp, $sp, -4   
    sw $t0, 0($sp)

    # arr[size] = item
    # $t0 = 4*size
    sll $t0,$a1,2
    # $t0 += arr
    add $t0,$t0,$a0
    # *(arr + size) = item
    sw $a2,0($t0)

    # restore $t0
    lw $t0, 0($sp)
    addi $sp, $sp,4   
    
    # return to caller
    jr $ra

########################## push_end end ##################################

# This is a routine for saving the
# current registers to the stack
save_routine:
    # with this routine $t0-$t7 are saved
    # save routine
    addi $sp, $sp, -32
    # push the stack pointer for 8 elements
    # sp[0] = t0
    sw $t0, 0($sp)
    # sp[1] = t1
    sw $t1, 4($sp)
    # sp[2] = t2
    sw $t2, 8($sp) 
    # sp[3] = t3
    sw $t3, 12($sp) 
    # sp[4] = t4
    sw $t4, 16($sp) 
    # sp[5] = t5
    sw $t5, 20($sp) 
    # sp[6] = t6
    sw $t6, 24($sp) 
    # sp[7] = t7
    sw $t7, 28($sp)
    
    jr $ra

# This is a routine for loading the
# current registers with the stack
restore_routine:
    # with this routine $t0-$t7 are restored
    # load routine 
    # t0 = sp[0]
    lw $t0, 0($sp)
    #  t1 = sp[1]
    lw $t1, 4($sp)
    #  t2 = sp[2]
    lw $t2, 8($sp) 
    #  t3 = sp[3]
    lw $t3, 12($sp) 
    #  t4 = sp[4]
    lw $t4, 16($sp) 
    #  t5 = sp[5]
    lw $t5, 20($sp) 
    #  t6 = sp[6]
    lw $t6, 24($sp) 
    #  t7 = sp[7]
    lw $t7, 28($sp)

    addi $sp, $sp, 32
    # pop the stack pointer for 8 elements
    # return to the caller 
    jr $ra

############################################################################
# void init_process_structure()
# _init_process_structure
# The process lists will be initialized here. 
# STATE_NO's : RUNNING = 1, BLOCKED = 2, READY = 3, TERMINATED = 0
# k1 -> current pid
############################################################################
_init_process_structure:

    li $v0,23
    syscall
    # will register this process as the init process.
    # set k1 as current process
    li $k1,0
    
   
    # temp $t7 = RUNNING state
    li $t7,1
    # process_states[0] = $t7 (RUNNING STATE)
    sw $t7,process_states

    jr $ra
########################## _init_process_structure end #####################
