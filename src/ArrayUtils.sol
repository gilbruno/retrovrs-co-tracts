// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;
library ArrayUtils {

    function deleteElement(uint[] storage myArray, uint index) public {
        require(index < myArray.length, "Index out of bounds");

        // Swap the element to be deleted with the last element
        myArray[index] = myArray[myArray.length - 1];

        // Remove the last element
        myArray.pop();
    }

}    