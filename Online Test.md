# DCS
## Online Test : Divider
1. Description:
   - Input is a sequence of 4 numbers encoded in Excess-3.(e.g. A>B>C>D. require sorting)
   - Obtain the **quotient** of ACD/B (no need to compute **remainder**.
2. Input:
   - clk, rst_n, in_valid
   - [4-1:0] in_data
3. Output:
   - out_valid, out_data
4. Procedure
   - Decode
     - The actual number is just obtained by (input-3)
   - Sort
     - Sort the 4 numbers obtained in first stage
   - Division
     - Use **Division by shifting and subtraction** method
     - No `/` or `%` allowed
   - Output
     - output the quotient from MSB to LSB serially(one bit per cycle)
