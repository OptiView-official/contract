// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library TimeUtils {
    function currentUtcDay() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }
}

