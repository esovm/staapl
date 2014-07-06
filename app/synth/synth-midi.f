staapl pic18/route
staapl pic18/compose-macro
staapl pic18/stdin
staapl pic18/cond

load midi-arp.f  \ keep track of which keys are pressed and in which order
\ load debug.f


variable midi-cin \ USB only
variable midi-byte0 : m0 midi-byte0 @ ;
variable midi-byte1 : m1 midi-byte1 @ ;
variable midi-byte2 : m2 midi-byte2 @ ;
    
variable pitch-lo  \ low  byte from midi, shifted left one bit
variable pitch-hi  \ high byte from midi

variable nrpn-addr-hi
variable nrpn-addr-lo
variable nrpn-val-hi
variable nrpn-val-lo
: nrpn-val15 \ -- lo hi | convert to 15-bit value
    nrpn-val-lo @ rot<<
    nrpn-val-hi @ ;
  
\ NRPN CC
: CC63 nrpn-addr-hi ! ; 
: CC62 nrpn-addr-lo ! ; 
: CC06 nrpn-val-hi ! ;
: CC26 nrpn-val-lo !
    \ This is optional in midi spec, though we require it to start
    \ transaction
    commit-nrpn ; 

: _dup over over ;
: _drop 2drop ;    

macro \ trampoline for far away jump addresses
: .. i/c . ;
forth  
    
\ low-level synth parameters are available through NRPN.
: commit-nrpn
    \ psps
    nrpn-addr-hi @ 0 = not if ; then \ ignore
    nrpn-val15
    nrpn-addr-lo @
    \ ` nrpn: .sym ts
    1 - 4 min
    \ ts
    route
        [ _p0    ] ..  \ 1
        [ _p1    ] ..  \ 2
        [ _p2    ] ..  \ 3
        [ _synth ] ..  \ 4
        _drop ;  \ ignore rest


        
\ Guard word: aborts call if condition is not met.
: ~chan m0 #x0F and 0 = if ; then xdrop ;
  
\ Handle USB MIDI Code Index Number

: 9x ~chan  m1 notes-add    play-last ;
: 8x ~chan  m1 notes-remove play-last ;
: Bx ~chan  CC  ;
: Ex ~chan  m2 << pitch-lo ! m2 pitch-hi ! ;
    
: pm12  m1 px m2 px cr ; \ pitchbend
    
: .synth ` synth: .sym  synth @ px cr ;
    


\ During silence we need to save synth config.
variable synth-save    

    
\ from midi-arp.f : get most recently pressed active key    
: play-last
    notes-last #xFF = if silence ; then
    notes-last midi note0
    \ square
: restore-synth    
    synth-save @ synth !
    ;

\ Controllers should set meaningful high level values.  The synth
\ engine is already fully controllable through NRPN.
    
: CC57
: CC58 
: CC59 
: CC5A 
: CC55 
: ____ drop ` ignore:cc: .sym pm12 ;
    
\ controller jump table.  this is sparse but we have plenty of room in Flash
: CC 
    m2 m1 #x7F and route
        \  0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
        ____ . ____ . ____ . ____ . ____ . ____ . CC06 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 0
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 1
        ____ . ____ . ____ . ____ . ____ . ____ . CC26 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 2 
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 3
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 4
        ____ . ____ . ____ . ____ . ____ . CC57 . ____ . CC57 . CC58 . CC59 . CC5A . ____ . ____ . ____ . ____ . ____ . \ 5
        ____ . ____ . CC62 . CC63 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 6
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ ; \ 7

\ Attempt to use as the same code for USB and good old current loop
\ calbe MIDI.

\ For old MIDI, the messages are not segmented so need "smart parsing"
\ if we want to get to a message payload before the next command byte
\ arrives.

\ It's always possible to segment based on command bytes, but that
\ introduces one byte delay.  Might not be a huge problem if the
\ device also sends tick messages.

\ So the idea is to have two entry points to this, one for usb and one
\ for cable midi.  Both call midi-route when a message has arrived.
\ Currently sysex is not supported (handle as a side-channel?)

        


    
: M0                                 midi-route ;
: M1 i> midi-byte1 !                 midi-route ;
: M2 i> midi-byte1 ! i> midi-byte2 ! midi-route ;
    

\ For MIDI cable, this can be called in a polling loop with i> set to
\ the UART input.  For midi USB this is called once per loop with i>
\ set to a> in the buffer.
    
: i>midi-bytes \ --
    i>
: cmd>midi-bytes \ cmd --
    1st 7 low? if drop ; next \ resync
    midi-byte0 !
    cmd-route
        M2 . M2 . M2 . M2 . \ 8 9 A B
        M2 . M1 . M2 . M0 ; \ C D E F

: midi-route
    m0 cmd-route
        8x . 9x .    . Bx .
           .    . Ex .    ;

: cmd-route rot>>4 8 - 7 and route ;


\ USB MIDI connected to EP 3

: midi-EP 3 ;

\ USB is named from pov. of host.  For midi words below, we use a
\ slightly less awkward device-centered view.
    
: midi-out-begin midi-EP 4 IN-begin ;
: midi-out-end   IN-end midi-EP IN-flush ;

: midi-in-begin  midi-EP 4 OUT-begin ;
: midi-in-end    OUT-end ;
    

\ FIXME: connect any panel pots to send out CC    
: note-on \ note --
    midi-out-begin
        #x09 >a  \ cable, class
        #x90 >a  \ note on channel 0
             >a  \ note value
        127  >a  \ velocity
    midi-out-end ;
    
: note-off \ note --
    midi-out-begin
        #x08 >a  \ cable, class
        #x80 >a  \ note on channel 0
             >a  \ note value
        127  >a  \ velocity
    midi-out-end ;


: midi-in \ -- class
    midi-in-begin
        a> midi-cin !
        a> midi-byte0 !
        a> midi-byte1 !
        a> midi-byte2 !
    midi-in-end ;

\ : note-in  begin midi-in m0 #x90 = until m1 ;
        

        

       
: midi-poll-once
    \ psps
    midi-in midi-cin @ #x0F and route
           .    .    .    .
           .    .    .    .
        8x . 9x .    . Bx .
           .    . Ex .    ;

: midi-poll begin midi-poll-once again
        
: go
    square synth @ synth-save ! silence
    init-notes engine-on 
    begin midi-poll-once rx-ready? until ;

    