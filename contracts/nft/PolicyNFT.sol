// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract PolicyNFT is ERC721, Ownable {
    error InsurancePoolNotConfigured();
    error CallerNotInsurancePool();
    error InvalidInsurancePool();
    error PolicyAlreadyMinted(uint256 policyId);

    address public insurancePool;
    string private _baseTokenUri;

    event InsurancePoolUpdated(address indexed previousPool, address indexed newPool);
    event BaseTokenUriUpdated(string newBaseTokenUri);
    event PolicyMinted(address indexed to, uint256 indexed policyId);

    constructor(
        address initialOwner,
        string memory baseTokenUri_
    ) ERC721("Insurance Policy NFT", "IPOL") Ownable(initialOwner) {
        _baseTokenUri = baseTokenUri_;
    }

    modifier onlyInsurancePool() {
        if (insurancePool == address(0)) {
            revert InsurancePoolNotConfigured();
        }
        if (msg.sender != insurancePool) {
            revert CallerNotInsurancePool();
        }
        _;
    }

    function setInsurancePool(
        address newInsurancePool
    ) external onlyOwner {
        if (newInsurancePool == address(0)) {
            revert InvalidInsurancePool();
        }

        emit InsurancePoolUpdated(insurancePool, newInsurancePool);
        insurancePool = newInsurancePool;
    }

    function setBaseTokenUri(
        string calldata newBaseTokenUri
    ) external onlyOwner {
        _baseTokenUri = newBaseTokenUri;
        emit BaseTokenUriUpdated(newBaseTokenUri);
    }

    function mint(
        address to,
        uint256 policyId
    ) external onlyInsurancePool {
        if (_ownerOf(policyId) != address(0)) {
            revert PolicyAlreadyMinted(policyId);
        }

        _safeMint(to, policyId);
        emit PolicyMinted(to, policyId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseUri = _baseURI();
        if (bytes(baseUri).length == 0) {
            return string.concat("policy:", Strings.toString(tokenId));
        }

        return string.concat(baseUri, Strings.toString(tokenId), ".json");
    }
}
