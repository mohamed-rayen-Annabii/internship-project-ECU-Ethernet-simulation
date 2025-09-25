#  ECU Fault Injection Simulation

This project simulates communication between two ECUs (Electronic Control Units) using Linux network namespaces and virtual Ethernet interfaces. It also supports automated **fault injection**, testing how the system behaves under different network faults.

---

##  Project Structure

ecus_simulation/
├── build/                     # Compiled ECU binaries (ecu1, ecu2)
├── faults/                   # Individual fault injection scripts
│   ├── block.sh
│   ├── corrupt.sh
│   ├── delay.sh
│   ├── loss.sh
│   └── reset.sh
├── test/                     # Fault injection test scripts and logs
│   ├── test_block.sh
│   ├── test_corrupt.sh
│   ├── test_delay.sh
│   ├── test_loss.sh
│   ├── generate_summary.sh
│   ├── block.log             # (generated after test runs)
│   ├── corrupt.log           # (generated after test runs)
│   ├── delay.log             # (generated after test runs)
│   ├── loss.log              # (generated after test runs)
│   └── results.md            # Auto-generated test summary
├── ecu1.cpp                  # Sends UDP message
├── ecu2.cpp                  # Receives UDP message
├── run_ecu1.sh               # Runs ecu1 inside namespace
├── run_ecu2.sh               # Runs ecu2 inside namespace
├── setup_netns.sh            # Creates netns + veth pairs
├── cleanup.sh               # Deletes namespaces and cleans up
├── Makefile                 # Compiles ecu1 and ecu2
├── .gitlab-ci.yml           # GitLab CI pipeline
└── README.md                # Project documentation


###  Core Simulation

- `ecu1.cpp`: Sends "status OK" every second via UDP to ECU2 
- `ecu2.cpp`: Listens for messages on UDP port 9090 
- `Makefile`: Compiles ECU binaries (`ecu1`, `ecu2`)
- `setup_netns.sh`: Creates two namespaces (`ecu1`, `ecu2`),  2 veth pair, bridge , assigns IPs, adds routes, and tests connectivity 
- `cleanup.sh`: Removes namespaces and interfaces cleanly 
- `run_ecu1.sh`: Runs `ecu1` inside its namespace 
- `run_ecu2.sh`: Runs `ecu2` inside its namespace 

---

##  Fault Injection (`faults/`)

Scripts in this directory inject different types of faults:

- `block.sh`: Blocks all traffic from ECU1 to ECU2 
- `delay.sh`: Adds 300ms delay 
- `loss.sh`: Adds 20% packet loss 
- `corrupt.sh`: Adds 5% packet corruption 
- `reset.sh`: Resets all faults (removes all netem rules)

>  Fault injection is done using `tc netem` and `iptables` inside the corresponding namespace interfaces.

---


make

#### Setup Network & Run Simulation

sudo ./setup_netns.sh
sudo ./run_ecu2.sh > ecu2_output.txt &
sudo ./run_ecu1.sh

#### Inject Faults Manually

sudo ./faults/block.sh       # Inject block
sudo ./faults/delay.sh       # Add delay
sudo ./faults/reset.sh       # Reset all faults

#### GitLab CI/CD Pipeline

The .gitlab-ci.yml automates:

	- build: Compile ECU binaries

	- simulate: Setup namespaces and verify basic communication

	- fault_test: Run each fault test

	- summary: Generate results report in test/results.md

All logs and results are saved as pipeline artifacts.

#### Cleanup

When finished, tear down the simulation cleanly:

sudo ./cleanup.sh

### Notes

- Make all scripts executable once:
chmod +x *.sh faults/*.sh test/*.sh
- To rerun a specific test:
./test/test_block.sh
./test/generate_summary.sh

