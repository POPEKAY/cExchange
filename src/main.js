import Web3 from "web3";
import { newKitFromWeb3 } from "@celo/contractkit";
import BigNumber from "bignumber.js";
import erc20Abi from "../contract/erc20.abi.json";
import stakerAbi from "../contract/staker.abi.json";
import cstkAbi from "../contract/cstk.abi.json";

const ERC20_DECIMALS = 18;
const STAKEPERIODS=["NOT SELECTED", "30 DAYS", "60 DAYS", "90 DAYS", "128 DAYS"]
const stakerContractAddress = "0x793a6db5190762F3cB8DF0997DA22f4287D0e3C8";
const cSTKContractAddress = "0xe0CA3C65e943351f3a050BB4b2847b073dd7203D";

let kit;
let stakerContract;
let cSTKContract;

const debounce = (func, timeout = 300) => {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => { func.apply(this, args); }, timeout);
    };
}

const connectCeloWallet = async function () {
    if (window.celo) {
        notification("⚠️ Please approve this DApp to use it.");
        try {
            await window.celo.enable();
            notificationOff();

            const web3 = new Web3(window.celo);
            kit = newKitFromWeb3(web3);

            const accounts = await kit.web3.eth.getAccounts();
            kit.defaultAccount = accounts[0];

            stakerContract = await new kit.web3.eth.Contract(
                stakerAbi,
                stakerContractAddress
            );
            cSTKContract = await new kit.web3.eth.Contract(
                cstkAbi,
                cSTKContractAddress
            );
        } catch (error) {
            notification(`⚠️ ${error}.`);
        }
    } else {
        notification("⚠️ Please install the CeloExtensionWallet.");
    }
};

function notification(_text) {
    document.querySelector(".alert").style.display = "block";
    document.querySelector("#notification").textContent = _text;
}

function notificationOff() {
    document.querySelector(".alert").style.display = "none";
}

const getBalance = async function () {
    const totalBalance = await kit.getTotalBalance(kit.defaultAccount);
    const cUSDBalance = totalBalance.CELO.shiftedBy(-ERC20_DECIMALS).toFixed(2);
    document.querySelector("#balance").textContent = cUSDBalance;
};

const renderSwapForCeloUI = async function (){
    const html = `
    <div class="container" id="swap-content">
    <div class="row justify-content-md-center">
        <div class="col-sm-12 col-md-8 col-lg-6">
            <form name="cSTKToCeloForm">
            <div class="form-floating">
            <input
                type="number"
                class="form-control"
                name="floatingcSTKInput"
                id="floatingcSTKInput"
                placeholder="cSTK"
                step="0.000001"
                min="0.000001"
            />
            <label for="floatingcSTKInput">cSTK</label>
        </div>
                
                <div
                    class="d-flex justify-content-center align-items-center p-2"
                >
                    <button type="button" class="btn btn-light">
                        <i class="bi bi-arrow-down-up"></i>
                    </button>
                </div>
                <div class="form-floating">
                    <input
                        type="number"
                        class="form-control"
                        id="floatingCeloInput"
                        placeholder="Celo"
                        disabled
                        value="0"
                    />
                    <label for="floatingCeloInput">Celo</label>
                </div>
                
                <button
                    type="submit"
                    id="Swap-cSTK-for-Celo"
                    class="btn btn-primary mt-2"
                >
                    Swap cSTK for Celo
                </button>
            </form>
        </div>
    </div>
</div>
    `

    document.getElementById("mainContainer").innerHTML = html;
}

const renderSwapForCSTKUI = async function (){
    const html = `
    <div class="container" id="swap-content">
    <div class="row justify-content-md-center">
        <div class="col-sm-12 col-md-8 col-lg-6">
            <form name="celoTocSTKForm">
                <div class="form-floating">
                    <input
                        type="number"
                        class="form-control"
                        name="floatingCeloInput"
                        id="floatingCeloInput"
                        placeholder="Celo"
                        step="0.000001"
                        min="0.000001"
                    />
                    <label for="floatingCeloInput">Celo</label>
                </div>
                <div
                    class="d-flex justify-content-center align-items-center p-2"
                >
                    <button type="button" class="btn btn-light">
                        <i class="bi bi-arrow-down-up"></i>
                    </button>
                </div>
                <div class="form-floating">
                    <input
                        type="number"
                        class="form-control"
                        id="floatingcSTKInput"
                        placeholder="cSTK"
                        value="0"
                        disabled
                    />
                    <label for="floatingcSTKInput">cSTK</label>
                </div>
                <button
                    type="submit"
                    id="Swap-Celo-for-cSTK"
                    class="btn btn-primary mt-2"
                >
                    Swap Celo for cSTK
                </button>
                
            </form>
        </div>
    </div>
</div>
    `

    document.getElementById("mainContainer").innerHTML = html;
}

const renderStakes = async function (stakes = []) {
    const html = `
    <div class="container" id="stake-content">
    <div class="row justify-content-md-center">
        ${!stakes.length ? '<div class="alert alert-warning" role="alert">You have made no staking</div>': "" } 
    </div>
    ${ stakes.length ? `
    <div class="row justify-content-md-center">
        <div class="col-sm-12 col-md-8">
            <table class="table table-hover">
                <thead>
                    <tr>
                      <th scope="col">#</th>
                      <th scope="col">amount</th>
                      <th scope="col">Timespan</th>
                      <th scope="col">Matures</th>
                      <th scope="col">Withdrawn</th>
                      <th scope="col">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${stakes.reduce((acummulator, stake, idx) => {
                        const temp = `
                        <tr>
                            <th scope="row">${stake.index}</th>
                            <td>${BigNumber(stake.amount).shiftedBy(-ERC20_DECIMALS ).toFixed(2)}</td>
                            <td>${STAKEPERIODS[stake.period]}</td>
                            <td>${new Date(stake.unlockTimestamp * 1000).toLocaleDateString()}</td>
                            <td>${stake.withdrawn}</td>
                            <td>
                                ${!stake.withdrawn && (stake.unlockTimestamp * 1000 < Date.now()) 
                                    ? `<button data-stake="${stake.index - 1}" class="withdraw-cstk-btn btn btn-success">Withdraw</button>`: 
                                    `<button data-stake="${stake.index - 1}" class="withdraw-cstk-btn btn btn-success" disabled>Withdraw</button>`}
                            </td>
                        </tr>
                        `;
                        return acummulator + temp;
                    }, "")}
                  </tbody>
            </table>
        </div>
    </div>`: ""}
</div>
    `
    document.getElementById("mainContainer").innerHTML = html;
}

const getCSTKBalance = async function () {
    console.log(kit.defaultAccount);
    const totalBalance = await cSTKContract.methods.balanceOf(kit.defaultAccount).call();
    const cSTKBalance = BigNumber(totalBalance).shiftedBy(-ERC20_DECIMALS).toFixed(2);
    document.querySelector("#cstk-balance").textContent = cSTKBalance;
};

const swapCeloForcSTk = async function (amountOfCelo) {
    const txn = await cSTKContract.methods.purchaseTokens().send({ from: kit.defaultAccount, value: amountOfCelo });
    return txn;
}

const swapcSTKForCelo = async function (amountOfcSTK) {
    await cSTKContract.methods.approve(cSTKContractAddress, amountOfcSTK).send({ from: kit.defaultAccount });
    const txn = await cSTKContract.methods.sellTokensForCelo(amountOfcSTK).send({ from: kit.defaultAccount });
    return txn;
}

const stakecSTK = async function (amountOfcSTK, stakePeriod) {
    const approve = await cSTKContract.methods.approve(stakerContractAddress, amountOfcSTK).send({ from: kit.defaultAccount });
    const txn = await stakerContract.methods.stakeForReward(amountOfcSTK, stakePeriod).send({ from: kit.defaultAccount });
    return txn;
}

const getAllStake = async function () {
    const numberOfStakes = await stakerContract.methods.numberOf(kit.defaultAccount).call();

    const stakes = [];

    for (let i = 0; i < numberOfStakes; i++) {
        let _stake = new Promise(async (resolve, reject) => {
            const stakeIndex = await stakerContract.methods.ownedStakes(kit.defaultAccount, i).call();
            const stake = await stakerContract.methods.stakes(stakeIndex).call();
            resolve({index: i+1, ...stake});
        });

        stakes.push(_stake);
    }

    const _stakes = await Promise.all(stakes);

    if (!_stakes.length) {
        return;
    }

    return _stakes;
}

const withdrawStake = async function (stakeIndex) {
    const txn = await stakerContract.methods.withdrawStake(stakeIndex).send({ from: kit.defaultAccount });
    return;
}

window.addEventListener("load", async () => {
    notification("⌛ Loading...");
    await connectCeloWallet();
    await getBalance();
    await getCSTKBalance();

    if(window.location.pathname.includes("stake")){
        renderStakes(await getAllStake());
        console.log("showit")
    }else if(window.location.pathname.includes("swap")){
        if(window.location.search.includes("token=celo")){
            renderSwapForCeloUI();
        }else {

            renderSwapForCSTKUI();
        }
    }

    notificationOff();
});

const estimateCeloTocSTK = debounce(async(celoAmount) => {
    const exchangeRate = await cSTKContract.methods.exchangeRate().call();
    const cSTKAmount = BigNumber(exchangeRate) * BigNumber(celoAmount).shiftedBy(ERC20_DECIMALS);

    document.querySelector("#floatingcSTKInput").value = BigNumber(cSTKAmount).shiftedBy(-ERC20_DECIMALS).toFixed(8);
})
const estimatecSTKToCelo = debounce(async(cSTKAmount) => {
    const exchangeRate = await cSTKContract.methods.exchangeRate().call();
    const celoAmount =  BigNumber(cSTKAmount).shiftedBy(ERC20_DECIMALS) / BigNumber(exchangeRate);

    document.querySelector("#floatingCeloInput").value = BigNumber(celoAmount).shiftedBy(-ERC20_DECIMALS).toFixed(8);
})


document.querySelector("#mainContainer").addEventListener("submit", async (e) => {
    e.preventDefault();
    e.stopPropagation();
    const formData = new FormData(e.target);

    notification(`⌛ Swapping Tokens...`);
    try {
        if(e.target.name === "cSTKToCeloForm"){
            await swapcSTKForCelo(BigNumber(formData.get("floatingcSTKInput")).shiftedBy(ERC20_DECIMALS));
        }else if(e.target.name === "celoTocSTKForm"){
            await swapCeloForcSTk(BigNumber(formData.get("floatingCeloInput")).shiftedBy(ERC20_DECIMALS));
        }

        notification(`🎉 You successfully swaped.`);
        window.location.reload();

    } catch (error) {
        console.log(error);
        notification(`⚠️ ${error}.`);
    } finally {
        // await getCSTKBalance();
        
    }
});

document.stakecSTKForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    e.stopPropagation();
    const formData = new FormData(e.target);
    console.log(formData.get("stakecSTKInput"));

    notification(`⌛ Staking cSTK ...`);
    try {
        document.querySelector("#stakecSTKFormFieldset").setAttribute("disabled", "disabled");
        await stakecSTK(
            new BigNumber(formData.get("stakecSTKInput")).shiftedBy(ERC20_DECIMALS),
            formData.get("stakecSTKPeriod")
        );
        notification(`🎉 You successfully added "${data.name}".`);

    } catch (error) {
        console.log(error);
        notification(`⚠️ ${error}.`);
    } finally {
        await getCSTKBalance();
        document.querySelector("#stakecSTKFormFieldset").removeAttribute("disabled");
    }
});

document.querySelector("#mainContainer").addEventListener("click", async (e) => {
    e.stopPropagation();
    // .withdraw-cstk-btn
    if(e.target.className.includes("withdraw-cstk-btn")){
        await withdrawStake(e.target.dataset.stake);
    }
});

document.querySelector("#mainContainer").addEventListener("change", async (e) => {
    e.stopPropagation();
    // .withdraw-cstk-btn
    if(e.target.id === "floatingCeloInput"){
        estimateCeloTocSTK(e.target.value);
    }else if(e.target.id === "floatingcSTKInput"){
        estimatecSTKToCelo(e.target.value);
    }
});