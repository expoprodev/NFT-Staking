// SPDX-License-Identifier: MIT
// String manipulation in Solidity 
/* Write a function which takes an array of strings as input and outputs  with one concatenated string. Function also should trim mirroring characters of each two consecutive array string elements. In two consecutive string elements "apple" and "electricity", mirroring characters are considered to be "le" and "el" and as a result these characters should be trimmed from both string elements, and concatenated string should be returned by the function. You may assume that array will consist of at least of one element, each element won't be an empty string. You may also assume that each element will contain only ascii characters. 
Example 1 input:  "apple", "electricity", "year" output: "appectricitear" 
Example 2 input: “abc”, “cb”, “ad” output: "aad"
*/

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Task3 {

    function trimMirroringChars(string[] memory data) public pure returns (string memory) {
            
        /**
        * Write your code here
        * Try to do with the lowest gas consumption.
        * If you will use some libraries or ready solutions,
        * please add links in the "notice" comments section before the function.
        */
        string memory result = string(abi.encodePacked("")); //abi.encodePacked spends less gas fee
        for (uint256 i = 0 ; i < data.length ; i++)
            result = chopMirrored(result, data[i]);
        // result = flipStr("apple");
        return result;
    }
    
    function chopMirrored(string memory _front, string memory _back) private pure returns (string memory) {
        
        string memory front; 
        
        front = flipStr(_front);

        uint256 length = bytes(_front).length > bytes(_back).length ? bytes(_back).length : bytes(_front).length;
        uint256 count = 0;
        
        for (uint256 i = 0 ; i < length ; i++) {
            if (bytes(front)[i] != bytes(_back)[i]) break;
            count++;
        }    

        string memory result = string(abi.encodePacked(""));
        
        for (uint256 i = 0 ; i < bytes(_front).length - count ; i++)
            result = string(abi.encodePacked(result, bytes(_front)[i]));
        for (uint256 i = count ; i < bytes(_back).length ; i++)
            result = string(abi.encodePacked(result, bytes(_back)[i]));
        
        return result;
    }

    function flipStr(string memory str) private pure returns (string memory) {
        bytes memory result = new bytes(bytes(str).length);
        for (uint256 i = 0 ; i < bytes(str).length ; i++) // uint256 spends less gas fee than uint8 or uint128 etc
            result[i] = bytes(str)[bytes(str).length - 1 - i];
        return string(result);
    }
}
