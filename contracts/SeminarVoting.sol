// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBestArwards.sol";
import "./libraries/Lib_AddressResolver.sol";

contract SeminarVoting is Ownable, Lib_AddressResolver {

    using Strings for uint256;

    // Sự kiện
    event RoundCreated(uint256 roundId, uint256 votingStart, uint256 votingDeadline, uint256 maxVotes);
    event SeminarAdded(uint256 id, uint256 roundId, string title, address[] speakers, string slideLink);
    event VoteSubmitted(uint256 roundId, address voter, uint256 seminarId);
    event SpeakerVoteSubmitted(uint256 roundId, address voter, address[] speakers);
    event InvalidVoteRemoved(uint256 roundId, address voter);
    event InvalidSpeakerVoteRemoved(uint256 roundId, address voter);
    event VotingStartChanged(uint256 roundId, uint256 newVotingStart);
    event VotingDeadlineChanged(uint256 roundId, uint256 newVotingDeadline);
    event VoterNameUpdated(address voter, string newName);
    event MaxVotesUpdated(uint256 roundId, uint256 newMaxVotes);
    event BestSpeakersNFTMinted(address speaker, uint256 tokenId);
    event BestSeminarNFTMinted(address recipient, uint256 tokenId);
    event VotingEnded(uint256 currentRoundId,  uint256[] seminarIds, address[] speakers);

    // Cấu trúc lưu trữ thông tin của một seminar
    struct Seminar {
        uint256 id;
        string title;        // Tên của seminar
        address[] speakers;   // Danh sách tên các diễn giả
        string slideLink;    // Đường link slide của seminar
    }

    // Cấu trúc lưu trữ thông tin của một vòng bầu chọn (round)
    struct Round {
        uint256 id;                // ID của round
        Seminar[] seminars;        // Danh sách các seminar
        uint256 votingStart;       // Thời gian bắt đầu
        uint256 votingDeadline;    // Thời gian kết thúc
        bool votingEnded;          // Đánh dấu vòng bầu chọn đã kết thúc hay chưa
        mapping(uint256 => uint256) seminarVoteCount; // Số lượng phiếu cho mỗi seminar
        mapping(address => uint256) speakerVoteCount; // Số lượng phiếu cho mỗi diễn giả
        mapping(address => uint256) seminarVotes; // Số lượng vote cho seminar của mỗi địa chỉ
        mapping(address => uint256) speakerVotes; // Số lượng vote cho diễn giả của mỗi địa chỉ
        mapping(address => uint256[]) votedSpeakers;   // Danh sách diễn giả đã được user vote
        address[] seminarVoters;          // Danh sách địa chỉ đã vote
        address[] speakerVoters;   // Danh sách địa chỉ đã vote cho diễn giả
        uint256 maxVotes;         // Số lượng tối đa vote cho seminar và speaker
    }

    // Danh sách các vòng bầu chọn
    Round[] public rounds;
    uint256 public currentRoundId;
    mapping(uint256 => string) seminarCertificateIdsToAddress;
    mapping(uint256 => string) speakerCertificateIdsToAddress;
    
    // Modifier để kiểm tra xem vòng bầu chọn có tồn tại hay không
    modifier roundExists(uint256 _roundId) {
        require(_roundId < rounds.length, "Round does not exist");
        _;
    }

    // Modifier chỉ cho phép thực hiện khi thời gian vote còn hiệu lực
    modifier voteActive() {
        Round storage round = rounds[currentRoundId];
        require(block.timestamp >= round.votingStart && block.timestamp < round.votingDeadline, "Voting is not active");
        _;
    }

    // Constructor để khởi tạo owner
    constructor(address _addressManager) Lib_AddressResolver(_addressManager){

    }

    // Hàm để tạo một vòng bầu chọn mới
    function createRound(uint256 _votingStart, uint256 _votingDuration, uint256 _maxVotes) public onlyOwner {
        uint256 roundId = rounds.length;
        rounds.push();
        Round storage newRound = rounds[roundId];
        newRound.id = roundId;
        newRound.votingStart = _votingStart;
        newRound.votingDeadline = _votingStart + _votingDuration;
        newRound.votingEnded = false;
        newRound.maxVotes = _maxVotes;  // Thiết lập số lượng vote tối đa
        currentRoundId = roundId;
        emit RoundCreated(roundId, _votingStart, newRound.votingDeadline, _maxVotes);
    }

    // Hàm để thêm seminar mới vào vòng bầu chọn hiện tại
    function addSeminar(uint256 _id, string memory _title, address[] memory _speakers, string memory _slideLink) 
        public 
        onlyOwner 
    {
        Round storage round = rounds[currentRoundId];
        round.seminars.push(Seminar(_id, _title, _speakers, _slideLink));
        emit SeminarAdded(_id, currentRoundId, _title, _speakers, _slideLink);
    }

    // Hàm để lấy danh sách các tên người đã vote cho seminar
    function geSeminarVoters() public view returns (address[] memory) {
        return rounds[currentRoundId].seminarVoters;
    }

    // Hàm để lấy danh sách các tên người đã vote cho speaker
    function getSpeakerVoters() public view returns (address[] memory) {
        return rounds[currentRoundId].speakerVoters;
    }

    // Hàm để vote cho seminar bằng ID trong vòng bầu chọn hiện tại
    function voteForSeminar(uint256[] calldata _seminarIds) 
        public 
        voteActive 
    {
        Round storage round = rounds[currentRoundId];
        
        // Kiểm tra số lượng vote hiện tại
        uint256 currentVotes = round.seminarVotes[msg.sender];
        require(currentVotes + _seminarIds.length <= round.maxVotes, "You have reached the maximum number of votes for seminars");

        // Đánh dấu là đã vote
        round.seminarVoters.push(msg.sender);

        for (uint256 i = 0; i < _seminarIds.length; i++) {
            uint256 seminarId = _seminarIds[i];
            require(seminarId < round.seminars.length, "Invalid seminar ID");

            // Cộng số lượng vote cho seminar được chỉ định
            round.seminarVoteCount[seminarId] += 1;
        }
        round.seminarVotes[msg.sender] += _seminarIds.length;
    }
    
    // Hàm để vote cho diễn giả bằng ID trong vòng bầu chọn hiện tại
    function voteForSpeakers(address[] memory _speakers) 
        public 
        voteActive 
    {
        Round storage round = rounds[currentRoundId];
        uint256 currentVotes = round.speakerVotes[msg.sender];
        
        // Kiểm tra tổng số vote đã thực hiện trong vòng hiện tại
        require(currentVotes + _speakers.length <= round.maxVotes, "You have reached the maximum number of votes for speakers in this round");

        // Tăng số lượng vote của người dùng lên theo số lượng speakers được vote trong lần gọi này
        round.speakerVotes[msg.sender] += _speakers.length;

        round.speakerVoters.push(msg.sender); // Thêm người dùng vào danh sách đã vote

        for (uint256 i = 0; i < _speakers.length; i++) {
            round.speakerVoteCount[_speakers[i]] += 1; // Cộng số lượng vote cho mỗi diễn giả
        }

        emit SpeakerVoteSubmitted(currentRoundId, msg.sender, _speakers);
    }

    // Hàm để xem số vote cho mỗi seminar sau khi kết thúc vote
    function getSeminarVotesByRoundId(uint256 _roundId) public view returns (uint256[] memory seminarIds, uint256[] memory votes) {
        Round storage round = rounds[_roundId];
        require(round.votingEnded, "Voting has not ended yet");

        votes = new uint256[](round.seminars.length);
        seminarIds = new uint256[](round.seminars.length);
        for (uint256 i = 0; i < round.seminars.length; i++) {
            votes[i] = round.seminarVoteCount[round.seminars[i].id];
            seminarIds[i] = round.seminars[i].id;
        }
    }

    // Hàm để xem số vote cho mỗi diễn giả sau khi kết thúc vote
    function getSpeakerVotesByRoundId(uint256 _roundId) public view returns (address[] memory speakers, uint256[] memory votes)  {
        Round storage round = rounds[_roundId];
        require(round.votingEnded, "Voting has not ended yet");

        votes = new uint256[](round.seminars.length);
        speakers = new address[](round.seminars.length);
        for (uint256 i = 0; i < round.seminars.length; i++) {
            for(uint256 j = 0; j < round.seminars[i].speakers.length; j++) {
                votes[i] = round.speakerVoteCount[round.seminars[i].speakers[i]];
                speakers[i] = round.seminars[i].speakers[i];
            }
        }
    }

    // Hàm để xem 3 diễn giả có số phiếu cao nhất
    function getWinnerSpeakersByRoundId(uint256 _roundId) public view returns (address[] memory topSpeakers, uint256[] memory topVotes) {
        Round storage round = rounds[_roundId];
        require(round.votingEnded, "Voting has not ended yet");

        // Tạo mảng để lưu các speaker và số phiếu của họ
        (address[] memory allSpeakers, uint256[] memory allVotes ) = getSpeakerVotesByRoundId(_roundId);

    

        // Tìm top 3 speakers có số phiếu cao nhất
        for (uint256 i = 0; i < speakerCount; i++) {
            for (uint256 j = i + 1; j < speakerCount; j++) {
                if (allVotes[j] > allVotes[i]) {
                    // Đổi chỗ votes
                    uint256 tempVotes = allVotes[i];
                    allVotes[i] = allVotes[j];
                    allVotes[j] = tempVotes;

                    // Đổi chỗ speakers
                    address tempSpeaker = allSpeakers[i];
                    allSpeakers[i] = allSpeakers[j];
                    allSpeakers[j] = tempSpeaker;
                }
            }
        }

        // Lấy top 3 speakers
        for (uint256 k = 0; k < 3 && k < speakerCount; k++) {
            topSpeakers[k] = allSpeakers[k];
            topVotes[k] = allVotes[k];
        }
    }

    // Hàm để xem danh sách diễn giả cho một round cụ thể
    function getSpeakersByRound(uint256 _roundId) public view returns (address[][] memory) {
        require(_roundId < rounds.length, "Round does not exist"); // Kiểm tra roundId có hợp lệ không
        Round storage round = rounds[_roundId];
        
        address[][] memory speakers = new address[][](round.seminars.length); // Khởi tạo mảng diễn giả

        for (uint256 i = 0; i < round.seminars.length; i++) {
            speakers[i] = round.seminars[i].speakers; // Gán danh sách diễn giả cho từng seminar
        }
        return speakers; // Trả về danh sách diễn giả
    }

    // Hàm để xem danh sách seminar cho một round cụ thể
    function getSeminarsByRound(uint256 _roundId) public view returns (uint256[] memory ids, string[] memory titles, address[][] memory speakers) {
        require(_roundId < rounds.length, "Round does not exist"); // Kiểm tra roundId có hợp lệ không
        Round storage round = rounds[_roundId];

        ids = new uint256[](round.seminars.length);
        titles = new string[](round.seminars.length); // Khởi tạo mảng tiêu đề seminar
        speakers = new address[][](round.seminars.length); // Khởi tạo mảng diễn giả

        for (uint256 i = 0; i < round.seminars.length; i++) {
            ids[i] = round.seminars[i].id;
            titles[i] = round.seminars[i].title; // Gán tiêu đề seminar
            speakers[i] = round.seminars[i].speakers; // Gán danh sách diễn giả cho từng seminar
        }
    }


    // Hàm để thay đổi thời gian bắt đầu vote cho một vòng bầu chọn
    function changeVotingStart(uint256 _newVotingStart) 
        public 
        onlyOwner 
        roundExists(currentRoundId) 
    {
        Round storage round = rounds[currentRoundId];
        round.votingStart = _newVotingStart;
        emit VotingStartChanged(currentRoundId, _newVotingStart);
    }

    // Hàm để thay đổi thời gian kết thúc vote cho một vòng bầu chọn
    function changeVotingDeadline(uint256 _newVotingDeadline) 
        public 
        onlyOwner 
        roundExists(currentRoundId) 
    {
        Round storage round = rounds[currentRoundId];
        round.votingDeadline = _newVotingDeadline;
        emit VotingDeadlineChanged(currentRoundId, _newVotingDeadline);
    }

    // Hàm để thay đổi số lượng tối đa vote cho một vòng bầu chọn
    function setMaxVotes(uint256 _maxVotes) public onlyOwner roundExists(currentRoundId) {
        Round storage round = rounds[currentRoundId];
        round.maxVotes = _maxVotes;
        emit MaxVotesUpdated(currentRoundId, _maxVotes);
    }


    function endVotingAndMintAwards() public onlyOwner {
        Round storage round = rounds[currentRoundId];
        require(block.timestamp >= round.votingDeadline, "Voting is not ended yet");
        require(!round.votingEnded, "Voting has already ended");

        (uint256[] memory seminarIdWinners, ) = getSeminarVotesByRoundId(currentRoundId);

        for(uint256 i = 0; i < round.maxVotes; i++) {
            // Mint NFT cho tất cả diễn giả của seminar chiến thắng
            Seminar memory bestSeminar = round.seminars[seminarIdWinners[i]];
            for (uint256 j = 0; j < bestSeminar.speakers.length; j++) {
                address speaker = bestSeminar.speakers[j];
                if (speaker != address(0)) {
                    uint256 tokenId = IBestArwards(resolve("SpeakerRewards")).mintNFT(speaker, seminarIdWinners[i], currentRoundId);
                    emit BestSpeakersNFTMinted(speaker, tokenId);
                }
            }
        }

        // // Tìm speaker có số phiếu bầu cao nhất dựa trên voteForSpeakers
        // uint256 maxSpeakerVotes = 0;
        // for (uint256 j = 0; j < bestSeminar.speakers.length; j++) {
        //     if (round.speakerVoteCount[bestSeminar.speakers[j]] > maxSpeakerVotes) {
        //         maxSpeakerVotes = round.speakerVoteCount[bestSeminar.speakers[j]];
        //     }
        // }

        // // Mint NFT cho những speakers có số phiếu bầu cao nhất
        // for (uint256 j = 0; j < bestSeminar.speakers.length; j++) {
        //     if (round.speakerVoteCount[bestSeminar.speakers[j]] == maxSpeakerVotes) {
        //         address speakerAddress = findSpeakerAddress(bestSeminar.speakers[j]);
        //         if (speakerAddress != address(0)) {
        //             uint256 tokenId = nftContract.mintAward(speakerAddress, "Best Speaker Award NFT URI");
        //             emit BestSpeakersNFTMinted(speakerAddress, tokenId);
        //         }
        //     }
        // }

        // round.votingEnded = true;
        // emit VotingEnded(currentRoundId, bestSeminarId);
    }
}