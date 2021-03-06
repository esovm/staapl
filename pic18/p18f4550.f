\ chip constants

load p18f4550-const.f
staapl pic18/pic18-serial
staapl pic18/pic18-serial-16

\ chip config macros for core code

macro
: init-chip
    \ 3-output
    ;

: init-serial | baud fosc |
    TRISC 7 high TRISC 6 low  \ pin tristate
    baud fosc async.init-brg-16 ;     

: debug-serial?
    PORTC 7 high? ;

: boot-size #x800 ; \ size of code-protect region.
    
forth
