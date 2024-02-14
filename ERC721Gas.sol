// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { IBlast } from "./interfaces/IBlast.sol";

abstract contract ERC721Gas is ERC721Enumerable {
    address private constant _BLAST_ADDRESS = 0x4300000000000000000000000000000000000002;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        IBlast(_BLAST_ADDRESS).configureClaimableYield();
        IBlast(_BLAST_ADDRESS).configureClaimableGas();
    }

    function _claimAllGas(address _address) internal virtual {
        IBlast(_BLAST_ADDRESS).claimAllGas(address(this), _address);
    }

    function readClaimableYield() external view virtual returns (uint256) {
        return IBlast(_BLAST_ADDRESS).readClaimableYield(address(this));
    }

    function readYieldConfiguration() external view virtual returns (uint8) {
        return IBlast(_BLAST_ADDRESS).readYieldConfiguration(address(this));
    }

    /**
     * @dev See {IERC721-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}