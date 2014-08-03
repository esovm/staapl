staapl pic18/route
staapl pic18/compose-macro
staapl pic18/stdin
staapl pic18/cond
staapl pic18/afregs
staapl pic18/double-math
staapl pic18/vector

\ https://ccrma.stanford.edu/~craig/articles/linuxmidi/misc/essenmidi.html
\ http://www.nortonmusic.com/midi_cc.html

variable midi-byte0 : m0 midi-byte0 @ ;
variable midi-byte1 : m1 midi-byte1 @ ;
variable midi-byte2 : m2 midi-byte2 @ ;
    
2variable pitch-mod  \ low  byte from midi, shifted left one bit
2variable mod1       

  
\ During silence we need to save synth config.
variable synth-save    

\ Main pitch
2variable period
 

: m-interpret \ --
    m0 midi-cmd route
        8x . 9x .    . Bx .
        Cx .    . Ex .    ;

: midi-cmd \ 0-7 | maps 9x-Fx to 0-7 for route command
    rot>>4 8 - 7 and ;
        
\ Guard: aborts caller if incorrect channel.
: ~chan m0 #x0F and 0 = if ; then xdrop ;
    
: 9x ~chan  m1 m2 0 = if notes-remove else notes-add then play-last ;
: 8x ~chan  m1 notes-remove play-last ;
: Bx ~chan  continuous-controller  ;
: Cx ~chan  m1 program-change ;    
: Ex ~chan  m1 m2 pitch-mod 2! ;
    

: play-last
    notes-last #xFF = if silence ; then
    notes-last midi-note
    _dup period 2!
    _p0
    \ square
: restore-synth    
    synth-save @ synth !
    ;

\ Controllers should set meaningful high level values.  The synth
\ engine is already fully controllable through NRPN.

2variable cc00 : init-cc00 cc00 -> drop ;  \ For development.

: CC00 cc00 invoke ;
: CC57 midi-note mod1 2! ;
: CC58 
: CC59 
: CC5A 
: CC55 
: ____ drop ; \ ` ignore:cc: .sym pm12 ;
    
\ jump table is sparse but we have plenty of room in Flash
: continuous-controller
    m2 m1 #x7F and route
        \  0      1      2      3      4      5      6      7      8      9      A      B      C      D      E      F
        CC00 . ____ . ____ . ____ . ____ . ____ . CC06 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 0
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 1
        ____ . ____ . ____ . ____ . ____ . ____ . CC26 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 2 
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 3
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 4
        ____ . ____ . ____ . ____ . ____ . CC57 . ____ . CC57 . CC58 . CC59 . CC5A . ____ . ____ . ____ . ____ . ____ . \ 5
        ____ . ____ . CC62 . CC63 . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . \ 6
        ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ . ____ ; \ 7


\ Eventually it might be interesting to find out a generic patch
\ format, but for now these are best pre-defined.
        
: program-change \ program --
    2 min route
        square .
        ;
    

\ USB PACKET / STREAM

\ usb>m | For USB MIDI, data is packetized already.
\ i>m   | For MIDI streams, the messages are not segmented so need
\ "smart parsing" if we want to get to a message payload before the
\ next command byte arrives.

\ ( It's always possible to segment based on command bytes, but that
\ introduces one byte delay.  This might actually not be a huge
\ problem if the device also sends tick messages. )



\ STREAM        



\ For MIDI cable, this can be called in a polling loop with i> set to
\ the UART input.  For midi USB this is called once per loop with i>
\ set to a> in the buffer.
    
\ Note this only works properly with d=i if the message is
\ well-formed.


        
\ NOT TESTED       
: midi>m \ --
    midi>
    1st 7 low? if midi-continuation ; then \ not a new command byte
    dup midi-byte0 !
    midi-cmd route
        midi>m12 . midi>m12 . midi>m12 . midi>m12 . \ 8 9 A B
        midi>m12 . midi>m1  . midi>m12 .          ; \ C D E F

: midi-continuation \ byte1 --
    midi-byte1 !
    m0 midi-cmd route
        midi>m2 . midi>m2 . midi>m2 . midi>m2 . \ 8 9 A B
        midi>m2 .         . midi>m2 .         ; \ C D E F
        
: midi>m1  midi> midi-byte1 ! ;
: midi>m2  midi> midi-byte2 ! ;
: midi>m12 midi>m1 midi>m2 ;
    



        



: init-synth
    square synth @ synth-save ! silence
    init-cc00
    init-notes
    engine-on ;
    

    


\ DEBUG: comment-out in standalone version
\ : a!midi-bytes midi-byte0 0 a!! ;
\ : m-clear a!midi-bytes 3 for 0 >a next ;
\ : m-print a>r a!midi-bytes 3 for a> px next cr r>a ;
\ : m-test 2 1 #x90 d>i i>m ;    
\ : .synth ` synth: .sym  synth @ px cr ;
\ : pm12  m1 px m2 px cr ;
    