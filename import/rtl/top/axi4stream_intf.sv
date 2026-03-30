interface axi4stream_intf #(
    parameter DATA_WIDTH = 64,
    parameter DEST_WIDTH = 4,
    parameter ID_WIDTH   = 4
);

    logic                       READY;
    logic                       VALID;
    logic [DATA_WIDTH-1:0]      DATA;
    logic [DATA_WIDTH/8-1:0]    KEEP;
    logic                       LAST;
    logic [ID_WIDTH-1:0]        ID;
    logic [DEST_WIDTH-1:0]      DEST;

    modport master (
        input   READY,
        output  VALID,
        output  DATA,
        output  KEEP,
        output  LAST,
        output  ID,
        output  DEST
    );

    modport slave (
        output  READY,
        input   VALID,
        input   DATA,
        input   KEEP,
        input   LAST,
        input   ID,
        input   DEST
    );

    modport monitor (
        input   READY,
        input   VALID,
        input   DATA,
        input   KEEP,
        input   LAST,
        input   ID,
        input   DEST
    );
endinterface

interface locallvds_if #(
    parameter DATA_WIDTH = 35,
);

    logic                       READY;
    logic                       PIX_CLK;
    logic [DATA_WIDTH-1:0]      PIX_DATA;

    modport master (
        input   READY,
        output  PIX_CLK,
        output  PIX_DATA
    );

    modport slave (
        output  READY,
        input   PIX_CLK,
        input   PIX_DATA
    );

    modport monitor (
        input   READY,
        input   PIX_CLK,
        input   PIX_DATA,
    );
endinterface
