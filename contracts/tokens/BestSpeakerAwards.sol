// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BestSpeakerArwards is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;

    struct NFTMetadata {
        uint256 tokenType;
        uint256 round;
    }

    mapping(uint256 => NFTMetadata) private _tokenData;
    mapping(address => bool) public isAdmin;
    string private baseURI;

    modifier onlyAdmin() {
        require(isAdmin[_msgSender()], "Invalid admin!");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_ // use ipfs
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }


    // Hàm mint NFT cho người chiến thắng
    function mintNFT(address recipient, uint256 _tokenType, uint256 _round) public onlyAdmin() returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _tokenData[newItemId] = NFTMetadata({
            tokenType: _tokenType,
            round: _round
        });

        _mint(recipient, newItemId);
        return newItemId;
    }

    function toggleAdmin(address _admin) external onlyOwner() {
        bool _isAdmin = isAdmin[_admin];
        isAdmin[_admin] = !_isAdmin;
    }

    function changeURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenData(uint256 _tokenId) public view returns(NFTMetadata memory) {
        return _tokenData[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );


        string memory base = _baseURI();

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, _tokenData[tokenId].tokenType.toString()));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
        require(from == address(0), "Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
       returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

}
