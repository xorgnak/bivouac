module Bivouac
  class Block
    attr_reader :index, :timestamp, :transactions, 
                :transactions_count, :previous_hash, 
                :nonce, :hash 
    
    def initialize(index, transactions, previous_hash)
      @index           = index
      @timestamp        = Time.now
      @transactions   = transactions
      @transactions_count  = transactions.size
      @previous_hash   = previous_hash
      @nonce, @hash    = compute_hash_with_proof_of_work
      return @hash
    end
    
    def compute_hash_with_proof_of_work(difficulty="00")
      nonce = 0
      loop do 
        hash = calc_hash_with_nonce(nonce)
        if hash.start_with?(difficulty)
          return [nonce, hash]
        else
          nonce +=1
        end
      end
    end
    
    def calc_hash_with_nonce(nonce=0)
      sha = Digest::SHA256.new
      sha.update( nonce.to_s + 
                  @index.to_s + 
                  @timestamp.to_s + 
                  @transactions.to_s + 
                  @transactions_count.to_s +
                  @previous_hash )
      sha.hexdigest 
    end
    
    def self.first( *transactions )    # Create genesis block
      ## Uses index zero (0) and arbitrary previous_hash ("0")
      Block.new( 0, transactions, "0" )
    end
    
    def self.next( previous, transactions )
      Block.new( previous.index+1, transactions, previous.hash )
    end
  end  # class Block

  module Chain
    LEDGER = Redis::List.new('CHAIN')
    LINK = Redis::Counter.new('LINK', start: 1)
    #####
    ## Blockchain building, one block at a time.
    ##  This will create a first block with fake transactions
    ## and then prompt user for transactions informations and set it in a new block.
    ## 
    ## Each block can take multiple transaction
    ## when a user has finish to add transaction, 
    ##  the block is added to the blockchain and writen in the ledger
    
    def self.ledger
      LEDGER
    end
    def self.create
      instance_variable_set("@b0", Block.first([{ from: '0', to: '0', what: 'genesis', qty: 0 }]))
      LEDGER << @b0
    end
    
    def self.add *t
      instance_variable_set("@b#{LINK.value}", Block.next((instance_variable_get("@b#{LINK.value - 1}")), [t].flatten)) 
      LEDGER << instance_variable_get("@b#{LINK.value}")
      p "============================"
      pp instance_variable_get("@b#{LINK.value}")
      p "============================"
      LINK.increment
    end

    def self.launcher
      puts "===========================" 
      puts "      NOMAD NETWORK        " 
      puts "==========================="
      Chain.create
    end
  end
  def self.chain
    Chain
  end
end
Bivouac.chain.launcher
