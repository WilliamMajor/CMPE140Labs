module datapath(
		input wire clk,
		input wire mult_en,
		input wire jump_reg,
		input wire rst,
		input wire pc_src,
		input wire jump,
		input wire we_reg,
		input wire alu_src,
		input wire dm2reg,
		input wire we_dm,
		input wire [2:0] alu_ctrl,
		input wire [1:0] reg_dst,
		input wire [1:0] mult_sel,
		input wire [4:0] ra3,
		input wire [31:0] instr,
		input wire [31:0] rd_dm,
		output wire zero,
		output wire we_dmE_out,
		output wire [31:0] pc_current,
		output wire [31:0] alu_outM_out,
		output wire [31:0] wd_dmM_out,
		output wire	[31:0] rd3
	);
    wire [4:0]  rf_wa;
    wire [31:0] pc_plus4, pc_pre, pc_next, sext_imm, ba, bta, jta, alu_pa, alu_pb, wd_rf;
    wire [63:0] mult_out;
    wire [31:0] lo_out, hi_out, mult_mux_out, jr_mux_out, alu_out;
    
    //Pipeline regs//
    wire [63:0] multM_out;
    wire [31:0]	instrD_out, pc_plus4D_out, pc_plus4E_out, alu_paE_out, instrE_out, seE_out ;
    wire [31:0]	alu_outW_out, rd_dmW_out, mult_loW_out, mult_hiW_out, pc_plus_brM_out, wd_dm;
    
    wire [4:0]	rf_waM_out, rf_waW_out;
    
    wire [2:0] alu_ctrlE_out;
    
    wire [1:0] reg_dstE_out;
    
    wire		alu_srcE_out, dm2regE_out, mult_enE_out, pc_srcE_out;
    wire		dm2regM_out, mult_enM_out, dm2regW_out, pc_srcM_out;
    
    assign ba = {seE_out[29:0], 2'b00};
    assign jta = {pc_plus4[31:28], instr[25:0], 2'b00};
    
    // --- PC Logic --- //
    dreg pc_reg (
		.clk	(clk),
		.rst	(rst),
		.d		(jr_mux_out),
		.q		(pc_current)
	);
	
    adder pc_plus_4	(
    	.a		(pc_current),
    	.b 		(4),
    	.y		(pc_plus4)
    );
    
    adder pc_plus_br (
    	.a		(pc_plus4E_out),
    	.b		(ba),
    	.y		(bta)
	);
	
    mux2 #(32) pc_src_mux (
    	.sel	(pc_srcM_out),
    	.a		(pc_plus4),
    	.b		(bta),
    	.y		(pc_pre)
	);
	
    mux2 #(32) pc_jmp_mux (
    	.sel	(jump),
    	.a		(pc_pre),
    	.b		(jta),
    	.y		(pc_next)
	);
    mux2 #(32) pc_jreg_mux (
    	.sel	(jump_reg),
    	.a		(pc_next),
    	.b		(alu_pa),
    	.y		(jr_mux_out)
	);
    
    // --- Pipeline Logic -- //
    pipe_reg_D pipe_reg_D (
    	.clk			(clk),
    	.rst			(rst),
    	.instrD_in		(instr),
    	.pc_plus4D_in	(pc_plus4),
    	.instrD_out		(instrD_out),
    	.pc_plus4D_out	(pc_plus4D_out)
	);
	
	pipe_reg_E pipe_reg_E (
		.clk			(clk),
		.rst			(rst),
		.alu_ctrlE_in	(alu_ctrl),
		.alu_srcE_in	(alu_src),
		.dm2regE_in		(dm2reg),
		.mult_enE_in	(mult_en),
		.we_dmE_in		(we_dm),
		.pc_srcE_in		(pc_src),
		.reg_dstE_in	(reg_dst),
		.pc_plus4E_in	(pc_plus4D_out),
		.alu_paE_in		(wd_dm),
		.instrE_in		(instrD_out),
		.seE_in			(sext_imm),
		.alu_ctrlE_out	(alu_ctrlE_out),
		.alu_srcE_out	(alu_srcE_out),
		.dm2regE_out	(dm2regE_out),
		.mult_enE_out	(mult_enE_out),
		.we_dmE_out		(we_dmE_out),
		.pc_srcE_out	(pc_srcE_out),
		.reg_dstE_out	(reg_dstE_out),
		.pc_plus4E_out	(pc_plus4E_out),
		.alu_paE_out	(alu_paE_out),
		.instrE_out		(instrE_out),	
		.seE_out		(seE_out)
	);
	
	pipe_reg_M	pipe_reg_M (
		.clk				(clk),
		.rst				(rst),
		.multM_in			(mult_out),
		.alu_outM_in		(alu_out),
		.wd_dmM_in			(wd_dm),
		.pc_plus_brM_in		(bta),
		.rf_waM_in			(rf_wa),
		.dm2regM_in			(dm2regE_out),
		.mult_enM_in		(mult_enE_out),
		.pc_srcM_in			(pc_srcE_out),
		.multM_out			(multM_out),
		.alu_outM_out		(alu_outM_out),
		.wd_dmM_out			(wd_dmM_out),
		.pc_plus_brM_out	(pc_plus_brM_out),
		.rf_waM_out			(rf_waM_out),
		.dm2regM_out		(dm2regM_out),
		.mult_enM_out		(mult_enM_out),
		.pc_srcM_out		(pc_srcM_out)
	);
    
    pipe_reg_W pipe_reg_W (
    	.clk			(clk),
    	.rst			(rst),
    	.alu_outW_in	(alu_outM_out),
    	.rd_dmW_in		(rd_dm),
    	.mult_loW_in	(lo_out),
    	.mult_hiW_in	(hi_out),
    	.rf_waW_in		(rf_waM_out),
    	.dm2regW_in		(dm2regM_out),
    	.alu_outW_out	(alu_outW_out),
    	.rd_dmW_out		(rd_dmW_out),
    	.mult_loW_out	(mult_loW_out),
    	.mult_hiW_out	(mult_hiW_out),
    	.rf_waW_out		(rf_waW_out),
    	.dm2regW_out	(dm2regW_out)
    );
    // --- RF Logic --- //
    mux4 #(5) rf_wa_mux (
    	.sel	(reg_dstE_out),
    	.a		(instrE_out[20:16]),
    	.b		(instrE_out[15:11]),
    	.c		(31),
    	.d		(0),
    	.y		(rf_wa)
	);
	
    regfile rf (
    	.clk	(clk),
    	.we		(we_reg),
    	.ra1	(instrD_out[25:21]),
    	.ra2	(instrD_out[20:16]),
    	.ra3	(ra3),
    	.wa		(rf_waW_out),
    	.wd		(mult_mux_out),
    	.rd1	(alu_pa),
    	.rd2	(wd_dm),
    	.rd3	(rd3)
	);
    
    signext se (
    	.a		(instrD_out[15:0]),
    	.y		(sext_imm)
	);
    
    // --- ALU Logic --- //
    mux2 #(32) alu_pb_mux (
    	.sel	(alu_srcE_out),
    	.a		(alu_paE_out),
    	.b		(seE_out),
    	.y		(alu_pb)
	);
    
    alu alu (
    	.op		(alu_ctrlE_out),
    	.a		(alu_pa), //This may need to be straight from the reg file... alu_pa... not 100% about timing
    	.b		(alu_pb),
    	.zero	(zero),
    	.y		(alu_out)
	);
    
    // --- MEM Logic --- //
    mux2 #(32) rf_wd_mux (
    	.sel	(dm2regW_out),
    	.a		(alu_outW_out),
    	.b		(rd_dmW_out),
    	.y		(wd_rf)
	);
    
    // --- MULTU Logic --- //
    mult multu (
    	.a		(alu_pa),//This may need to be straight from the reg file... alu_pa... not 100% about timing
    	.b		(wd_dm),
    	.y		(mult_out)
	);
    
    dreg2 lo (
    	.clk	(clk),
    	.rst	(rst),
    	.en		(mult_enM_out),
    	.d		(multM_out[31:0]),
    	.q		(lo_out)
	);
    
    dreg2 hi (
    	.clk	(clk),
    	.rst	(rst),
    	.en		(mult_enM_out),
    	.d		(multM_out[63:32]),
    	.q		(hi_out)
	);
    
    mux4 #(32) mult_mux (
    	.sel	(mult_sel),
    	.a		(pc_plus4D_out),
    	.b		(wd_rf),
    	.c		(mult_loW_out),
    	.d		(mult_hiW_out),
    	.y		(mult_mux_out)
	);
    
endmodule