# DCS
## Final Project : Job Assignment Machine(JAM)
1. Description:
   - N jobs are to be assigned to N workers, the JAM will find an optimal solution where the total cost is minimized.
   - We will implement N=8 JAM in the Final Project.
   - The input will be 64 cycles the cost of each job by different workers will be given each cycle.
2. Input:
   - clk, rst_n, in_valid
   - [7-1:0] in_cost
3. Output:
   - out_valid
   - [4-1:0] out_job
   - [10-1:0] out_cost
4. Hungarian Method:
   [Hungarian Method using Python](https://www.796t.com/content/1544340782.html)
   [Hungarian Method explained](https://egyankosh.ac.in/bitstream/123456789/18143/1/Unit-12.pdf)