interface axi4mm_intf #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_WIDTH  = 1,
    parameter BUSER_WIDTH  = 1,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_WIDTH  = 1
);

    // ============================================================
    // Write Address Channel (AW)
    // ============================================================
    logic [ID_WIDTH-1:0]        AWID;
    logic [ADDR_WIDTH-1:0]     AWADDR;
    logic [7:0]                 AWLEN;
    logic [2:0]                AWSIZE;
    logic [1:0]                AWBURST;
    logic                      AWVALID;
    logic                      AWREADY;
    logic [AWUSER_WIDTH-1:0]  AWUSER;

    // ============================================================
    // Write Data    // ========================================================= Channel (W)
===
    logic [ID_WIDTH-1:0]       WID;
    logic [DATA_WIDTH-1:0]     WDATA;
    logic [DATA_WIDTH/8-1:0]   WSTRB;
    logic                       WLAST;
    logic                       WVALID;
    logic                       WREADY;
    logic [WUSER_WIDTH-1:0]    WUSER;

    // ============================================================
    // Write Response Channel (B)
    // ============================================================
    logic [ID_WIDTH-1:0]       BID;
    logic [1:0]                BRESP;
    logic                       BVALID;
    logic                       BREADY;
    logic [BUSER_WIDTH-1:0]    BUSER;

    // ============================================================
    // Read Address Channel (AR)
    // ============================================================
    logic [ID_WIDTH-1:0]       ARID;
    logic [ADDR_WIDTH-1:0]    ARADDR;
    logic [7:0]               ARLEN;
    logic [2:0]               ARSIZE;
    logic [1:0]               ARBURST;
    logic                      ARVALID;
    logic                      ARREADY;
    logic [ARUSER_WIDTH-1:0]  ARUSER;

    // ============================================================
    // Read Data Channel (R)
    // ============================================================
    logic [ID_WIDTH-1:0]       RID;
    logic [DATA_WIDTH-1:0]     RDATA;
    logic [1:0]                RRESP;
    logic                       RLAST;
    logic                       RVALID;
    logic                       RREADY;
    logic [RUSER_WIDTH-1:0]    RUSER;

    // ============================================================
    // Global Signals
    // ============================================================
    logic                       ACLK;
    logic                       ARESETN;

    // --------------------------------------------------------
    // Master Port
    // --------------------------------------------------------
    modport master (
        // Global
        input   ACLK,
        input   ARESETN,

        // AW Channel
        output  AWID,
        output  AWADDR,
        output  AWLEN,
        output  AWSIZE,
        output  AWBURST,
        output  AWVALID,
        input   AWREADY,
        output  AWUSER,

        // W Channel
        output  WID,
        output  WDATA,
        output  WSTRB,
        output  WLAST,
        output  WVALID,
        input   WREADY,
        output  WUSER,

        // B Channel
        input   BID,
        input   BRESP,
        input   BVALID,
        output  BREADY,
        input   BUSER,

        // AR Channel
        output  ARID,
        output  ARADDR,
        output  ARLEN,
        output  ARSIZE,
        output  ARBURST,
        output  ARVALID,
        input   ARREADY,
        output  ARUSER,

        // R Channel
        input   RID,
        input   RDATA,
        input   RRESP,
        input   RLAST,
        input   RVALID,
        output  RREADY,
        input   RUSER
    );

    // --------------------------------------------------------
    // Slave Port
    // --------------------------------------------------------
    modport slave (
        // Global
        input   ACLK,
        input   ARESETN,

        // AW Channel
        input   AWID,
        input   AWADDR,
        input   AWLEN,
        input   AWSIZE,
        input   AWBURST,
        input   AWVALID,
        output  AWREADY,
        input   AWUSER,

        // W Channel
        input   WID,
        input   WDATA,
        input   WSTRB,
        input   WLAST,
        input   WVALID,
        output  WREADY,
        input   WUSER,

        // B Channel
        output  BID,
        output  BRESP,
        output  BVALID,
        input   BREADY,
        output  BUSER,

        // AR Channel
        input   ARID,
        input   ARADDR,
        input   ARLEN,
        input   ARSIZE,
        input   ARBURST,
        input   ARVALID,
        output  ARREADY,
        input   ARUSER,

        // R Channel
        output  RID,
        output  RDATA,
        output  RRESP,
        output  RLAST,
        output  RVALID,
        input   RREADY,
        output  RUSER
    );

    // --------------------------------------------------------
    // Monitor Port (all inputs)
    // --------------------------------------------------------
    modport monitor (
        // Global
        input   ACLK,
        input   ARESETN,

        // AW Channel
        input   AWID,
        input   AWADDR,
        input   AWLEN,
        input   AWSIZE,
        input   AWBURST,
        input   AWVALID,
        input   AWREADY,
        input   AWUSER,

        // W Channel
        input   WID,
        input   WDATA,
        input   WSTRB,
        input   WLAST,
        input   WVALID,
        input   WREADY,
        input   WUSER,

        // B Channel
        input   BID,
        input   BRESP,
        input   BVALID,
        input   BREADY,
        input   BUSER,

        // AR Channel
        input   ARID,
        input   ARADDR,
        input   ARLEN,
        input   ARSIZE,
        input   ARBURST,
        input   ARVALID,
        input   ARREADY,
        input   ARUSER,

        // R Channel
        input   RID,
        input   RDATA,
        input   RRESP,
        input   RLAST,
        input   RVALID,
        input   RREADY,
        input   RUSER
    );

endinterface