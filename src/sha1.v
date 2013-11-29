`define H0INIT 32'h67452301
`define H1INIT 32'hefcdab89
`define H2INIT 32'h98badcfe
`define H3INIT 32'h10325476
`define H4INIT 32'hc3d2e1f0

`define K0 32'h5a827999
`define K1 32'h6ed9eba1
`define K2 32'h8f1bbcdc
`define K3 32'hca62c1d6

module sha1 #(parameter WORDNUM  = 16,
              parameter WORDSIZE = 32,
              parameter WSIZE    = 480) (
  oDat, oReady, iDat, iClk, iInitial, iValid);

  output [159:0]       oDat;
  output               oReady;
  reg                  oReady;
  input [WORDSIZE-1:0] iDat;
  input                iClk;
  input                iInitial, iValid;

  reg [6:0]          loop;
  reg [WORDSIZE-1:0] H0, H1, H2, H3, H4;
  reg [WSIZE-1:0]    W;
  reg [WORDSIZE-1:0] Wt, Kt;
  reg [WORDSIZE-1:0] A, B, C, D, E;

  wire [WORDSIZE-1:0] f1, f2, f3, WtRaw, WtROTL1;
  wire [WORDSIZE-1:0] ft;
  wire [WORDSIZE-1:0] T;
  wire [WORDSIZE-1:0] ROTLB;

  assign f1 = (B & C) ^ (~B & D);
  assign f2 = B ^ C ^ D;
  assign f3 = (B & C) ^ (C & D) ^ (B & D);
  assign ft = (loop < 21) ? f1 : ((loop < 41) ? f2 : ((loop < 61) ? f3 : f2));

  assign WtRaw = {W[(WORDNUM- 2)*WORDSIZE-1:(WORDNUM- 3)*WORDSIZE] ^
                  W[(WORDNUM- 7)*WORDSIZE-1:(WORDNUM- 8)*WORDSIZE] ^
                  W[(WORDNUM-13)*WORDSIZE-1:(WORDNUM-14)*WORDSIZE] ^
                  W[(WORDNUM-15)*WORDSIZE-1:(WORDNUM-16)*WORDSIZE]};

  assign WtROTL1 = {WtRaw[WORDSIZE-2:0], WtRaw[WORDSIZE-1]};

  assign T = {A[WORDSIZE-6:0], A[WORDSIZE-1:WORDSIZE-5]} + ft + E + Kt + Wt;

  assign ROTLB = {B[1:0],B[WORDSIZE-1:2]};
  assign oDat  = {H0, H1, H2, H3, H4};

  always @(posedge iClk)
    if (loop < 20)        Kt <= `K0;
    else if (loop < 40)   Kt <= `K1;
    else if (loop < 60)   Kt <= `K2;
    else                  Kt <= `K3;

  always @(posedge iClk) begin
    if (loop < WORDNUM) Wt <= iDat;
    else                Wt <= WtROTL1;
    if ((loop < WORDNUM-1) & iValid)
      W[WSIZE-1:0] <= {iDat, W[WSIZE-1:WORDSIZE]};
    else if (loop > WORDNUM-1)
      W[WSIZE-1:0] <= {Wt,W[(WORDNUM-1)*WORDSIZE-1:WORDSIZE]};
  end

  always @(posedge iClk)
    if (loop == 0) begin
      if (iValid) begin
        if (iInitial) begin
          A  <= `H0INIT; B  <= `H1INIT; C  <= `H2INIT;
          D  <= `H3INIT; E  <= `H4INIT;
          H0 <= `H0INIT; H1 <= `H1INIT; H2 <= `H2INIT;
          H3 <= `H3INIT; H4 <= `H4INIT;
        end
        else begin
          A <= H0; B <= H1; C <= H2; D <= H3; E <= H4;
        end
        oReady <= 0;
        loop <= loop + 1;
      end
      else
        oReady <= 1;
      end
   else if (loop == 80) begin
      H0 <= T     + H0;
      H1 <= A     + H1;
      H2 <= ROTLB + H2;
      H3 <= C     + H3;
      H4 <= D     + H4;
      oReady <= 1;
      loop <= 0;
   end
   else if (loop < 80) begin
     E <= D;
     D <= C;
     C <= ROTLB;
     B <= A;
     A <= T;
     loop <= loop + 1;
   end
   else
     loop <= 0;
endmodule


module sha1tst;

  wire [159:0] oDat;
  wire         oReady;
  reg  [31:0]  iDat;
  reg          iClk;
  reg          iInitial;
  reg          iValid;

  sha1 SHA(oDat, oReady, iDat, iClk, iInitial, iValid);

  initial begin
    iClk = 0;
    iInitial = 0;
    iValid = 0;
  end

  always #50 iClk = ~iClk;
/*
  initial begin
    #250  iInitial = 1;
          iValid   = 1;
          iDat     = 32'h61626380;
    #100 iValid   = 1;
         iInitial = 0;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h00000018;
    #100 iValid   = 0;
         iDat     = 32'h0;
  end
*/

  initial begin
    #250  iInitial = 1;
          iValid   = 1;
          iDat     = 32'h00000000;
    #100 iValid   = 1;
         iInitial = 0;
         iDat     = 32'h204b6565;
    #100 iValid   = 1;
         iInitial = 0;
         iDat     = 32'h7020796f;
    #100 iValid   = 1;
         iDat     = 32'h75722046;
    #100 iValid   = 1;
         iDat     = 32'h50474120;
    #100 iValid   = 1;
         iDat     = 32'h7370696e;
    #100 iValid   = 1;
         iDat     = 32'h6e696e67;
    #100 iValid   = 1;
         iDat     = 32'h21800000;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h000000E8;
    #100 iValid   = 0;
         iDat     = 32'h0;
         
    // NEW DATA
    /*
    #10000 iInitial = 1;
          iValid  = 1;
          iDat    = 32'h61616161;
    #100 iValid   = 1;
         iInitial = 0;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h000001C0;
    #100 iValid   = 0;
         iDat     = 32'h0;
         
    // NEW DATA
    #10000 iInitial = 1;
          iValid  = 1;
          iDat    = 32'h61616161;
    #100 iValid   = 1;
         iInitial = 0;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616161;
    #100 iValid   = 1;
         iDat     = 32'h61616180;
    #100 iValid   = 1;
         iDat     = 32'h0;
    #100 iValid   = 1;
         iDat     = 32'h000001B8;
    #100 iValid   = 0;
         iDat     = 32'h0;*/
  end

endmodule

