# File saved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS-threadsafe
# 
# non-default properties - (restore without -noprops)
property attrcolor #000000
property attrfontsize 8
property autobundle 1
property backgroundcolor #ffffff
property boxcolor0 #000000
property boxcolor1 #000000
property boxcolor2 #000000
property boxinstcolor #000000
property boxpincolor #000000
property buscolor #008000
property closeenough 5
property createnetattrdsp 2048
property decorate 1
property elidetext 40
property fillcolor1 #ffffcc
property fillcolor2 #dfebf8
property fillcolor3 #f0f0f0
property gatecellname 2
property instattrmax 30
property instdrag 15
property instorder 1
property marksize 12
property maxfontsize 15
property maxzoom 6.25
property netcolor #19b400
property objecthighlight0 #ff00ff
property objecthighlight1 #ffff00
property objecthighlight2 #00ff00
property objecthighlight3 #0095ff
property objecthighlight4 #8000ff
property objecthighlight5 #ffc800
property objecthighlight7 #00ffff
property objecthighlight8 #ff00ff
property objecthighlight9 #ccccff
property objecthighlight10 #0ead00
property objecthighlight11 #cefc00
property objecthighlight12 #9e2dbe
property objecthighlight13 #ba6a29
property objecthighlight14 #fc0188
property objecthighlight15 #02f990
property objecthighlight16 #f1b0fb
property objecthighlight17 #fec004
property objecthighlight18 #149bff
property objecthighlight19 #eb591b
property overlapcolor #19b400
property pbuscolor #000000
property pbusnamecolor #000000
property pinattrmax 20
property pinorder 2
property pinpermute 0
property portcolor #000000
property portnamecolor #000000
property ripindexfontsize 8
property rippercolor #000000
property rubberbandcolor #000000
property rubberbandfontsize 15
property selectattr 0
property selectionappearance 2
property selectioncolor #0000ff
property sheetheight 44
property sheetwidth 68
property showmarks 1
property shownetname 0
property showpagenumbers 1
property showripindex 4
property timelimit 1
#
module new dog_top work:dog_top:NOFILE -nosplit
load symbol gaussian_blur_top work:gaussian_blur_top:NOFILE HIERBOX pin addr_reg_rep_3_2 input.left pin addr_reg_rep_3_3 input.left pin blur2_valid input.left pin clear input.left pin clk_IBUF_BUFG input.left pin done2 input.left pin done_OBUF output.right pin rst_IBUF input.left pin start_IBUF input.left pinBus ADDRBWRADDR input.left [0:0] pinBus D output.right [7:0] pinBus E output.right [0:0] pinBus O input.left [0:0] pinBus Q input.left [7:0] pinBus addr_reg_rep_3 input.left [3:0] pinBus addr_reg_rep_3_0 input.left [3:0] pinBus addr_reg_rep_3_1 input.left [3:0] pinBus pixel_out_reg[7] output.right [8:0] boxcolor 1 fillcolor 2 minwidth 13%
load symbol gaussian_blur_top__parameterized0 work:gaussian_blur_top__parameterized0:NOFILE HIERBOX pin Q output.right pin blur2_valid output.right pin clear output.right pin clk_IBUF_BUFG input.left pin done2 output.right pin rom_en_reg_0 output.right pin rst_IBUF input.left pin start_IBUF input.left pinBus ADDRBWRADDR output.right [0:0] pinBus D input.left [7:0] pinBus O output.right [0:0] pinBus addr_reg[0] output.right [3:0] pinBus addr_reg[12] output.right [3:0] pinBus addr_reg[8] output.right [3:0] pinBus pixel_out_reg[7] output.right [7:0] boxcolor 1 fillcolor 2 minwidth 13%
load symbol BUFG hdi_primitives BUF pin O output pin I input fillcolor 1
load symbol IBUF hdi_primitives BUF pin O output pin I input fillcolor 1
load symbol OBUF hdi_primitives BUF pin O output pin I input fillcolor 1
load symbol FDRE hdi_primitives GEN pin Q output.right pin C input.clk.left pin CE input.left pin D input.left pin R input.left fillcolor 1
load port clk input -pg 1 -lvl 0 -x 0 -y 1190
load port dog_valid output -pg 1 -lvl 7 -x 1800 -y 1440
load port done output -pg 1 -lvl 7 -x 1800 -y 1520
load port rst input -pg 1 -lvl 0 -x 0 -y 1260
load port start input -pg 1 -lvl 0 -x 0 -y 1330
load portBus dog_pixel output [8:0] -attr @name dog_pixel[8:0] -pg 1 -lvl 7 -x 1800 -y 80
load inst blur_pipe_1 gaussian_blur_top work:gaussian_blur_top:NOFILE -autohide -attr @cell(#000000) gaussian_blur_top -pinBusAttr ADDRBWRADDR @name ADDRBWRADDR -pinBusAttr D @name D[7:0] -pinBusAttr E @name E -pinBusAttr O @name O -pinBusAttr Q @name Q[7:0] -pinBusAttr addr_reg_rep_3 @name addr_reg_rep_3[3:0] -pinBusAttr addr_reg_rep_3_0 @name addr_reg_rep_3_0[3:0] -pinBusAttr addr_reg_rep_3_1 @name addr_reg_rep_3_1[3:0] -pinBusAttr pixel_out_reg[7] @name pixel_out_reg[7][8:0] -pg 1 -lvl 4 -x 1090 -y 1140
load inst blur_pipe_2 gaussian_blur_top__parameterized0 work:gaussian_blur_top__parameterized0:NOFILE -autohide -attr @cell(#000000) gaussian_blur_top__parameterized0 -pinBusAttr ADDRBWRADDR @name ADDRBWRADDR -pinBusAttr D @name D[7:0] -pinBusAttr O @name O -pinBusAttr addr_reg[0] @name addr_reg[0][3:0] -pinBusAttr addr_reg[12] @name addr_reg[12][3:0] -pinBusAttr addr_reg[8] @name addr_reg[8][3:0] -pinBusAttr pixel_out_reg[7] @name pixel_out_reg[7][7:0] -pg 1 -lvl 3 -x 520 -y 1100
load inst clk_IBUF_BUFG_inst BUFG hdi_primitives -attr @cell(#000000) BUFG -pg 1 -lvl 2 -x 180 -y 1190
load inst clk_IBUF_inst IBUF hdi_primitives -attr @cell(#000000) IBUF -pg 1 -lvl 1 -x 40 -y 1190
load inst dog_pixel_OBUF[0]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 80
load inst dog_pixel_OBUF[1]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 230
load inst dog_pixel_OBUF[2]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 380
load inst dog_pixel_OBUF[3]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 530
load inst dog_pixel_OBUF[4]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 680
load inst dog_pixel_OBUF[5]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 830
load inst dog_pixel_OBUF[6]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 980
load inst dog_pixel_OBUF[7]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 1130
load inst dog_pixel_OBUF[8]_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 1280
load inst dog_pixel_reg[0] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 80
load inst dog_pixel_reg[1] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 230
load inst dog_pixel_reg[2] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 380
load inst dog_pixel_reg[3] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 530
load inst dog_pixel_reg[4] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 680
load inst dog_pixel_reg[5] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 830
load inst dog_pixel_reg[6] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 980
load inst dog_pixel_reg[7] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 1130
load inst dog_pixel_reg[8] FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 1280
load inst dog_valid_OBUF_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 1440
load inst dog_valid_reg FDRE hdi_primitives -attr @cell(#000000) FDRE -pg 1 -lvl 5 -x 1460 -y 1440
load inst done_OBUF_inst OBUF hdi_primitives -attr @cell(#000000) OBUF -pg 1 -lvl 6 -x 1590 -y 1520
load inst rst_IBUF_inst IBUF hdi_primitives -attr @cell(#000000) IBUF -pg 1 -lvl 2 -x 180 -y 1260
load inst start_IBUF_inst IBUF hdi_primitives -attr @cell(#000000) IBUF -pg 1 -lvl 2 -x 180 -y 1330
load net <const1> -power -pin dog_valid_reg CE
load net blur2_valid -pin blur_pipe_1 blur2_valid -pin blur_pipe_2 blur2_valid
netloc blur2_valid 1 3 1 820 1230n
load net blur_pipe_1_n_2 -attr @rip(#000000) D[7] -pin blur_pipe_1 D[7] -pin blur_pipe_2 D[7]
load net blur_pipe_1_n_3 -attr @rip(#000000) D[6] -pin blur_pipe_1 D[6] -pin blur_pipe_2 D[6]
load net blur_pipe_1_n_4 -attr @rip(#000000) D[5] -pin blur_pipe_1 D[5] -pin blur_pipe_2 D[5]
load net blur_pipe_1_n_5 -attr @rip(#000000) D[4] -pin blur_pipe_1 D[4] -pin blur_pipe_2 D[4]
load net blur_pipe_1_n_6 -attr @rip(#000000) D[3] -pin blur_pipe_1 D[3] -pin blur_pipe_2 D[3]
load net blur_pipe_1_n_7 -attr @rip(#000000) D[2] -pin blur_pipe_1 D[2] -pin blur_pipe_2 D[2]
load net blur_pipe_1_n_8 -attr @rip(#000000) D[1] -pin blur_pipe_1 D[1] -pin blur_pipe_2 D[1]
load net blur_pipe_1_n_9 -attr @rip(#000000) D[0] -pin blur_pipe_1 D[0] -pin blur_pipe_2 D[0]
load net blur_pipe_2_n_0 -pin blur_pipe_1 addr_reg_rep_3_2 -pin blur_pipe_2 rom_en_reg_0
netloc blur_pipe_2_n_0 1 3 1 800 1270n
load net blur_pipe_2_n_1 -pin blur_pipe_1 addr_reg_rep_3_3 -pin blur_pipe_2 Q
netloc blur_pipe_2_n_1 1 3 1 900 1150n
load net blur_pipe_2_n_10 -attr @rip(#000000) addr_reg[8][2] -pin blur_pipe_1 addr_reg_rep_3_0[2] -pin blur_pipe_2 addr_reg[8][2]
load net blur_pipe_2_n_11 -attr @rip(#000000) addr_reg[8][1] -pin blur_pipe_1 addr_reg_rep_3_0[1] -pin blur_pipe_2 addr_reg[8][1]
load net blur_pipe_2_n_12 -attr @rip(#000000) addr_reg[8][0] -pin blur_pipe_1 addr_reg_rep_3_0[0] -pin blur_pipe_2 addr_reg[8][0]
load net blur_pipe_2_n_13 -attr @rip(#000000) addr_reg[12][3] -pin blur_pipe_1 addr_reg_rep_3[3] -pin blur_pipe_2 addr_reg[12][3]
load net blur_pipe_2_n_14 -attr @rip(#000000) addr_reg[12][2] -pin blur_pipe_1 addr_reg_rep_3[2] -pin blur_pipe_2 addr_reg[12][2]
load net blur_pipe_2_n_15 -attr @rip(#000000) addr_reg[12][1] -pin blur_pipe_1 addr_reg_rep_3[1] -pin blur_pipe_2 addr_reg[12][1]
load net blur_pipe_2_n_16 -attr @rip(#000000) addr_reg[12][0] -pin blur_pipe_1 addr_reg_rep_3[0] -pin blur_pipe_2 addr_reg[12][0]
load net blur_pipe_2_n_17 -attr @rip(#000000) O[0] -pin blur_pipe_1 O[0] -pin blur_pipe_2 O[0]
netloc blur_pipe_2_n_17 1 3 1 920 1130n
load net blur_pipe_2_n_18 -attr @rip(#000000) ADDRBWRADDR[0] -pin blur_pipe_1 ADDRBWRADDR[0] -pin blur_pipe_2 ADDRBWRADDR[0]
netloc blur_pipe_2_n_18 1 3 1 940 1110n
load net blur_pipe_2_n_19 -attr @rip(#000000) pixel_out_reg[7][7] -pin blur_pipe_1 Q[7] -pin blur_pipe_2 pixel_out_reg[7][7]
load net blur_pipe_2_n_20 -attr @rip(#000000) pixel_out_reg[7][6] -pin blur_pipe_1 Q[6] -pin blur_pipe_2 pixel_out_reg[7][6]
load net blur_pipe_2_n_21 -attr @rip(#000000) pixel_out_reg[7][5] -pin blur_pipe_1 Q[5] -pin blur_pipe_2 pixel_out_reg[7][5]
load net blur_pipe_2_n_22 -attr @rip(#000000) pixel_out_reg[7][4] -pin blur_pipe_1 Q[4] -pin blur_pipe_2 pixel_out_reg[7][4]
load net blur_pipe_2_n_23 -attr @rip(#000000) pixel_out_reg[7][3] -pin blur_pipe_1 Q[3] -pin blur_pipe_2 pixel_out_reg[7][3]
load net blur_pipe_2_n_24 -attr @rip(#000000) pixel_out_reg[7][2] -pin blur_pipe_1 Q[2] -pin blur_pipe_2 pixel_out_reg[7][2]
load net blur_pipe_2_n_25 -attr @rip(#000000) pixel_out_reg[7][1] -pin blur_pipe_1 Q[1] -pin blur_pipe_2 pixel_out_reg[7][1]
load net blur_pipe_2_n_26 -attr @rip(#000000) pixel_out_reg[7][0] -pin blur_pipe_1 Q[0] -pin blur_pipe_2 pixel_out_reg[7][0]
load net blur_pipe_2_n_5 -attr @rip(#000000) addr_reg[0][3] -pin blur_pipe_1 addr_reg_rep_3_1[3] -pin blur_pipe_2 addr_reg[0][3]
load net blur_pipe_2_n_6 -attr @rip(#000000) addr_reg[0][2] -pin blur_pipe_1 addr_reg_rep_3_1[2] -pin blur_pipe_2 addr_reg[0][2]
load net blur_pipe_2_n_7 -attr @rip(#000000) addr_reg[0][1] -pin blur_pipe_1 addr_reg_rep_3_1[1] -pin blur_pipe_2 addr_reg[0][1]
load net blur_pipe_2_n_8 -attr @rip(#000000) addr_reg[0][0] -pin blur_pipe_1 addr_reg_rep_3_1[0] -pin blur_pipe_2 addr_reg[0][0]
load net blur_pipe_2_n_9 -attr @rip(#000000) addr_reg[8][3] -pin blur_pipe_1 addr_reg_rep_3_0[3] -pin blur_pipe_2 addr_reg[8][3]
load net clear -pin blur_pipe_1 clear -pin blur_pipe_2 clear
netloc clear 1 3 1 780 1250n
load net clk -port clk -pin clk_IBUF_inst I
netloc clk 1 0 1 NJ 1190
load net clk_IBUF -pin clk_IBUF_BUFG_inst I -pin clk_IBUF_inst O
netloc clk_IBUF 1 1 1 NJ 1190
load net clk_IBUF_BUFG -pin blur_pipe_1 clk_IBUF_BUFG -pin blur_pipe_2 clk_IBUF_BUFG -pin clk_IBUF_BUFG_inst O -pin dog_pixel_reg[0] C -pin dog_pixel_reg[1] C -pin dog_pixel_reg[2] C -pin dog_pixel_reg[3] C -pin dog_pixel_reg[4] C -pin dog_pixel_reg[5] C -pin dog_pixel_reg[6] C -pin dog_pixel_reg[7] C -pin dog_pixel_reg[8] C -pin dog_valid_reg C
netloc clk_IBUF_BUFG 1 2 3 340 1370 740 1450 1310
load net dog_pixel0[0] -attr @rip(#000000) pixel_out_reg[7][0] -pin blur_pipe_1 pixel_out_reg[7][0] -pin dog_pixel_reg[0] D
load net dog_pixel0[1] -attr @rip(#000000) pixel_out_reg[7][1] -pin blur_pipe_1 pixel_out_reg[7][1] -pin dog_pixel_reg[1] D
load net dog_pixel0[2] -attr @rip(#000000) pixel_out_reg[7][2] -pin blur_pipe_1 pixel_out_reg[7][2] -pin dog_pixel_reg[2] D
load net dog_pixel0[3] -attr @rip(#000000) pixel_out_reg[7][3] -pin blur_pipe_1 pixel_out_reg[7][3] -pin dog_pixel_reg[3] D
load net dog_pixel0[4] -attr @rip(#000000) pixel_out_reg[7][4] -pin blur_pipe_1 pixel_out_reg[7][4] -pin dog_pixel_reg[4] D
load net dog_pixel0[5] -attr @rip(#000000) pixel_out_reg[7][5] -pin blur_pipe_1 pixel_out_reg[7][5] -pin dog_pixel_reg[5] D
load net dog_pixel0[6] -attr @rip(#000000) pixel_out_reg[7][6] -pin blur_pipe_1 pixel_out_reg[7][6] -pin dog_pixel_reg[6] D
load net dog_pixel0[7] -attr @rip(#000000) pixel_out_reg[7][7] -pin blur_pipe_1 pixel_out_reg[7][7] -pin dog_pixel_reg[7] D
load net dog_pixel0[8] -attr @rip(#000000) pixel_out_reg[7][8] -pin blur_pipe_1 pixel_out_reg[7][8] -pin dog_pixel_reg[8] D
load net dog_pixel[0] -attr @rip(#000000) 0 -port dog_pixel[0] -pin dog_pixel_OBUF[0]_inst O
load net dog_pixel[1] -attr @rip(#000000) 1 -port dog_pixel[1] -pin dog_pixel_OBUF[1]_inst O
load net dog_pixel[2] -attr @rip(#000000) 2 -port dog_pixel[2] -pin dog_pixel_OBUF[2]_inst O
load net dog_pixel[3] -attr @rip(#000000) 3 -port dog_pixel[3] -pin dog_pixel_OBUF[3]_inst O
load net dog_pixel[4] -attr @rip(#000000) 4 -port dog_pixel[4] -pin dog_pixel_OBUF[4]_inst O
load net dog_pixel[5] -attr @rip(#000000) 5 -port dog_pixel[5] -pin dog_pixel_OBUF[5]_inst O
load net dog_pixel[6] -attr @rip(#000000) 6 -port dog_pixel[6] -pin dog_pixel_OBUF[6]_inst O
load net dog_pixel[7] -attr @rip(#000000) 7 -port dog_pixel[7] -pin dog_pixel_OBUF[7]_inst O
load net dog_pixel[8] -attr @rip(#000000) 8 -port dog_pixel[8] -pin dog_pixel_OBUF[8]_inst O
load net dog_pixel_OBUF[0] -pin dog_pixel_OBUF[0]_inst I -pin dog_pixel_reg[0] Q
netloc dog_pixel_OBUF[0] 1 5 1 N 80
load net dog_pixel_OBUF[1] -pin dog_pixel_OBUF[1]_inst I -pin dog_pixel_reg[1] Q
netloc dog_pixel_OBUF[1] 1 5 1 N 230
load net dog_pixel_OBUF[2] -pin dog_pixel_OBUF[2]_inst I -pin dog_pixel_reg[2] Q
netloc dog_pixel_OBUF[2] 1 5 1 N 380
load net dog_pixel_OBUF[3] -pin dog_pixel_OBUF[3]_inst I -pin dog_pixel_reg[3] Q
netloc dog_pixel_OBUF[3] 1 5 1 N 530
load net dog_pixel_OBUF[4] -pin dog_pixel_OBUF[4]_inst I -pin dog_pixel_reg[4] Q
netloc dog_pixel_OBUF[4] 1 5 1 N 680
load net dog_pixel_OBUF[5] -pin dog_pixel_OBUF[5]_inst I -pin dog_pixel_reg[5] Q
netloc dog_pixel_OBUF[5] 1 5 1 N 830
load net dog_pixel_OBUF[6] -pin dog_pixel_OBUF[6]_inst I -pin dog_pixel_reg[6] Q
netloc dog_pixel_OBUF[6] 1 5 1 N 980
load net dog_pixel_OBUF[7] -pin dog_pixel_OBUF[7]_inst I -pin dog_pixel_reg[7] Q
netloc dog_pixel_OBUF[7] 1 5 1 N 1130
load net dog_pixel_OBUF[8] -pin dog_pixel_OBUF[8]_inst I -pin dog_pixel_reg[8] Q
netloc dog_pixel_OBUF[8] 1 5 1 N 1280
load net dog_valid -port dog_valid -pin dog_valid_OBUF_inst O
netloc dog_valid 1 6 1 NJ 1440
load net dog_valid0 -attr @rip(#000000) E[0] -pin blur_pipe_1 E[0] -pin dog_pixel_reg[0] CE -pin dog_pixel_reg[1] CE -pin dog_pixel_reg[2] CE -pin dog_pixel_reg[3] CE -pin dog_pixel_reg[4] CE -pin dog_pixel_reg[5] CE -pin dog_pixel_reg[6] CE -pin dog_pixel_reg[7] CE -pin dog_pixel_reg[8] CE -pin dog_valid_reg D
netloc dog_valid0 1 4 1 1370 70n
load net dog_valid_OBUF -pin dog_valid_OBUF_inst I -pin dog_valid_reg Q
netloc dog_valid_OBUF 1 5 1 NJ 1440
load net done -port done -pin done_OBUF_inst O
netloc done 1 6 1 NJ 1520
load net done2 -pin blur_pipe_1 done2 -pin blur_pipe_2 done2
netloc done2 1 3 1 760 1270n
load net done_OBUF -pin blur_pipe_1 done_OBUF -pin done_OBUF_inst I
netloc done_OBUF 1 4 2 1330J 1520 NJ
load net rst -port rst -pin rst_IBUF_inst I
netloc rst 1 0 2 NJ 1260 NJ
load net rst_IBUF -pin blur_pipe_1 rst_IBUF -pin blur_pipe_2 rst_IBUF -pin dog_pixel_reg[0] R -pin dog_pixel_reg[1] R -pin dog_pixel_reg[2] R -pin dog_pixel_reg[3] R -pin dog_pixel_reg[4] R -pin dog_pixel_reg[5] R -pin dog_pixel_reg[6] R -pin dog_pixel_reg[7] R -pin dog_pixel_reg[8] R -pin dog_valid_reg R -pin rst_IBUF_inst O
netloc rst_IBUF 1 2 3 360 1390 720 1470 1390
load net start -port start -pin start_IBUF_inst I
netloc start 1 0 2 NJ 1330 NJ
load net start_IBUF -pin blur_pipe_1 start_IBUF -pin blur_pipe_2 start_IBUF -pin start_IBUF_inst O
netloc start_IBUF 1 2 2 380 1410 NJ
load netBundle @dog_pixel 9 dog_pixel[8] dog_pixel[7] dog_pixel[6] dog_pixel[5] dog_pixel[4] dog_pixel[3] dog_pixel[2] dog_pixel[1] dog_pixel[0] -autobundled
netbloc @dog_pixel 1 6 1 1780 80n
load netBundle @blur_pipe_1_n_ 8 blur_pipe_1_n_2 blur_pipe_1_n_3 blur_pipe_1_n_4 blur_pipe_1_n_5 blur_pipe_1_n_6 blur_pipe_1_n_7 blur_pipe_1_n_8 blur_pipe_1_n_9 -autobundled
netbloc @blur_pipe_1_n_ 1 2 3 400 1350 720J 1090 1290
load netBundle @dog_pixel0 9 dog_pixel0[8] dog_pixel0[7] dog_pixel0[6] dog_pixel0[5] dog_pixel0[4] dog_pixel0[3] dog_pixel0[2] dog_pixel0[1] dog_pixel0[0] -autobundled
netbloc @dog_pixel0 1 4 1 1350 90n
load netBundle @blur_pipe_2_n_ 4 blur_pipe_2_n_5 blur_pipe_2_n_6 blur_pipe_2_n_7 blur_pipe_2_n_8 -autobundled
netbloc @blur_pipe_2_n_ 1 3 1 880 1170n
load netBundle @blur_pipe_2_n__1 4 blur_pipe_2_n_13 blur_pipe_2_n_14 blur_pipe_2_n_15 blur_pipe_2_n_16 -autobundled
netbloc @blur_pipe_2_n__1 1 3 1 N 1210
load netBundle @blur_pipe_2_n__2 4 blur_pipe_2_n_9 blur_pipe_2_n_10 blur_pipe_2_n_11 blur_pipe_2_n_12 -autobundled
netbloc @blur_pipe_2_n__2 1 3 1 840 1190n
load netBundle @blur_pipe_2_n__3 8 blur_pipe_2_n_19 blur_pipe_2_n_20 blur_pipe_2_n_21 blur_pipe_2_n_22 blur_pipe_2_n_23 blur_pipe_2_n_24 blur_pipe_2_n_25 blur_pipe_2_n_26 -autobundled
netbloc @blur_pipe_2_n__3 1 3 1 860 1190n
levelinfo -pg 1 0 40 180 520 1090 1460 1590 1800
pagesize -pg 1 -db -bbox -sgen -80 0 1940 1560
show
fullfit
#
# initialize ictrl to current module dog_top work:dog_top:NOFILE
ictrl init topinfo |
