pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../tokens/SingularityNetToken.sol";
import "./MarketJobInterface.sol";


contract MarketJob is MarketJobInterface {
    using SafeMath for uint256;

    SingularityNetToken public token;
    address public masterAgent;
    uint256 public jobDescriptorHash;
    bool public jobCompleted;
    bool public jobAccepted;
    uint256 public jobResult;
    address public payer;

    event Deposited(address payer, uint256 amount);
    event Withdrew(address payee, uint256 amount);
    event JobCompleted();
    event JobAccepted();


    struct Job {
        uint256 amount;
        uint256 idService;
    }

    mapping (address => Job) public amounts;

    modifier jobDone {
        require(jobCompleted == true);
        _;
    }

    modifier jobApproved {
        require(jobAccepted == true);
        _;
    }

    modifier jobPending {
        require(jobCompleted == false);
        _;
    }

    modifier onlyPayer {
        require(msg.sender == payer);
        _;
    }

    modifier onlyMasterAgent {
        require(msg.sender == masterAgent);
        _;
    }

    function MarketJob(
        address[] _agents,
        uint256[] _amounts,
        uint256[] _services,
        address _token,
        address _payer,
        uint256 _jobDescriptorHash
    ) public
    {
        require(_agents.length == _amounts.length);
        require(_amounts.length == _services.length);
        masterAgent = msg.sender;
        payer = _payer;
        jobDescriptorHash = _jobDescriptorHash;
        jobCompleted = false;
        token = SingularityNetToken(_token);

        for (uint256 i = 0; i < _amounts.length; i++) {
            amounts[_agents[i]] = Job(_amounts[i],_services[i]);
        }
    }

    function deposit(uint256 amount) onlyPayer jobPending external payable {
        require(token.transferFrom(msg.sender, address(this), amount));
        Deposited(msg.sender,amount);
    }

    function setJobCompleted(uint256 _jobResult) external onlyMasterAgent jobPending {
        jobCompleted = true;
        jobResult = _jobResult;
        JobCompleted();
    }

    function setJobAccepted() external onlyPayer jobDone {
        jobAccepted = true;
        JobAccepted();
    }

    function withdraw() external jobDone jobApproved {
        address agent = msg.sender;
        uint256 amount = amounts[agent].amount;
        require(amount > 0);

        amounts[agent].amount = 0;
        require(token.transfer(agent,amount));
        Withdrew(agent,amount);
    }
}
