// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract RightAngledTriangle {
    //To check if a triangle with side lenghts a,b,c is a right angled triangle
    function check(uint a, uint b, uint c) public pure returns (bool) {
        if (a<=0 || b<=0 || c<=0){
            return false;
        }
        if(a >= b ){
            if(a >= c){
                return a*a == b*b + c*c;
            }
            else{
                return c*c == a*a + b*b;
            }
        }
        else{
            if(b >= c){
                return b*b == a*a + c*c;
            }
            return c*c == a*a + b*b;
        }
    }
}
