// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

import { ERC721Gas } from "./ERC721Gas.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

    enum BlastPenguinTicketID {
        OGSale,
        Presale,
        AllowList
    }

    error MaxSupplyOver();
    error NotEnoughFunds();
    error NotMintable();
    error InvalidMerkleProof();
    error AlreadyClaimedMax();
    error MintAmountOver();

contract BlastPenguin is ERC721Gas, AccessControl {
    using Strings for uint256;

    string private constant _BASE_EXTENSION = ".json";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 private constant PUBLIC_MAX_PER_TX = 10;

    bool public publicSale = true;
    bool public mintable = true;

    uint256 public publicCost = 0.01 ether;
    string private _baseMetadataURI = "https://bafybeic36rpsrhskkceipn7mhpyg43nqic6f6qf2aenbyhzoudfzv2gjii.ipfs.nftstorage.link/";

    mapping(BlastPenguinTicketID => uint256) public presaleCost;
    mapping(BlastPenguinTicketID => bool) public presalePhase;
    mapping(BlastPenguinTicketID => bytes32) public merkleRoot;
    mapping(BlastPenguinTicketID => mapping(address => uint256)) public whiteListClaimed;
    mapping(uint256 => string) private _metadataURI;

    constructor() ERC721Gas("BlastPenguin", "BLAST") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(CLAIM_ROLE, _msgSender());
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_metadataURI[tokenId]).length == 0) {
            return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), _BASE_EXTENSION));
        } else {
            return _metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _metadataURI[tokenId] = metadata;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable whenMintable {
        uint256 supply = totalSupply();
        if (msg.value < publicCost * _mintAmount) revert NotEnoughFunds();
        if (supply + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(_to, supply + i);
        }
    }

    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, BlastPenguinTicketID ticket) external payable whenMintable {
        uint256 supply = totalSupply();
        if (supply + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < presaleCost[ticket] * _mintAmount) revert NotEnoughFunds();
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf)) revert InvalidMerkleProof();
        if (whiteListClaimed[ticket][msg.sender] + _mintAmount > _presaleMax) revert AlreadyClaimedMax();

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, supply + i);
        }

        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function ownerMint(address _address, uint256 _count) public onlyRole(MINTER_ROLE) {
        uint256 supply = totalSupply();
        if (supply + _count > MAX_SUPPLY) revert MaxSupplyOver();
        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(_address, supply + i);
        }
    }

    function setPresalePhase(bool _state, BlastPenguinTicketID _phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[_phase] = _state;
    }

    function setPresaleCost(uint256 _cost, BlastPenguinTicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(uint256 _publicCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, BlastPenguinTicketID _phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[_phase] = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseMetadataURI = _newBaseURI;
    }

    function withdraw(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }

    function claimAllGas(address _address) external onlyRole(CLAIM_ROLE) {
        _claimAllGas(_address);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Gas, AccessControl) returns (bool) {
        return ERC721Gas.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}