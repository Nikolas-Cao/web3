import { utils, BigNumber } from 'ethers';
import React from 'react';
import NetworkConfigInterface from '../../../../smart-contract/lib/NetworkConfigInterface';

interface Props {
  networkConfig: NetworkConfigInterface;
  maxSupply: number;
  totalSupply: number;
  tokenPrice: BigNumber;
  maxMintAmountPerTx: number;
  isPaused: boolean;
  loading: boolean;
  isWhitelistMintEnabled: boolean;
  isUserInWhitelist: boolean;
  whitelistAlreadyClaimed: boolean;
  mintTokens(mintAmount: number): Promise<void>;
  whitelistMintTokens(mintAmount: number): Promise<void>;
}

interface State {
  mintAmount: number;
}

const defaultState: State = {
  mintAmount: 1
}

export default class MintWidget extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = defaultState;
  }

  private canMint(): boolean {
    return !this.props.isPaused || this.canWhitelistMint();
  }

  private canWhitelistMint(): boolean {
    return this.props.isWhitelistMintEnabled && this.props.isUserInWhitelist;
  }

  private isWhitelistClaimedBlocked(): boolean {
    return this.canWhitelistMint() && this.props.whitelistAlreadyClaimed;
  }

  private incrementMintAmount(): void {
    this.setState({
      mintAmount: Math.min(this.props.maxMintAmountPerTx, this.state.mintAmount + 1)
    })
  }

  private decrementMintAmount(): void {
    this.setState({
      mintAmount: Math.max(1, this.state.mintAmount - 1)
    })
  }

  private async mint(): Promise<void> {
    if (!this.props.isPaused) {
      await this.props.mintTokens(this.state.mintAmount);
      return
    }

    await this.props.whitelistMintTokens(this.state.mintAmount);
  }

  render() {
    if (!this.canMint()) {
      return (
        <div className="cannot-min">
          <span className="emoji">🚫</span>
          {this.props.isWhitelistMintEnabled ? <>you are not included in the whitelisted</> : <>the contract is paused</>}
          please come back during the next sale !
        </div>
      );
    }

    if (this.isWhitelistClaimedBlocked()) {
      return (
        <div className="mint-widget whitelist-already-claimed">
          <div className="preview">
            <img src="./build/images/preview.png" alt="Collection Preview" />
          </div>
          <div className="already-claimed-message">
            <span className="emoji">✅</span>
            <strong>You have already claimed your whitelist mint.</strong>
            <p>Each address can only mint once during the whitelist sale. Come back when the public sale opens!</p>
          </div>
        </div>
      );
    }

    return (
      <div className={`mint-widget ${this.props.loading ? 'animate-pulse saturate-0 pointer-events-none' : ''}`}>
        <div className="preview">
          <img src="./build/images/preview.png" alt="Collection Preview" />
        </div>

        <div className="price">
          <strong>Total Price : </strong> {utils.formatEther(this.props.tokenPrice.mul(this.state.mintAmount))} {this.props.networkConfig.symbol}
        </div>

        <div className="controls">
          <button className="decrease" disabled={this.props.loading} onClick={() => this.decrementMintAmount()}>-</button>
          <span className="mint-amount">{this.state.mintAmount}</span>
          <button className="increase" disabled={this.props.loading} onClick={() => this.incrementMintAmount()}>+</button>
          <button className="primary" disabled={this.props.loading} onClick={() => this.mint()}>Mint {this.state.mintAmount} tokens</button>
        </div>
      </div>
    );
  }
}