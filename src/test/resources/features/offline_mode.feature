Feature: Offline Mode

	Background:
		Given the internet is reachable
		And an initialised environment
		And I have configured "offline_mode" to "true"

	# install

	Scenario: Install a version that is present under the candidates folder
		Given the candidate "java" version "21.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install java 21.0.0"
		Then I see "Setting java 21.0.0 as default."
		And the candidate "java" version "21.0.0" should be the default
		And the exit code is 0

	Scenario: Install a version by passing its path under the candidates folder
		Given the candidate "java" version "21.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install java 21.0.0 .sdkman/candidates/java/21.0.0"
		Then I see "Setting java 21.0.0 as default."
		And the candidate "java" version "21.0.0" should be the default
		And the exit code is 0

	Scenario: Install the version that is already current
		Given the candidate "java" version "21.0.0" is already installed and default
		And the system is bootstrapped
		When I enter "sdk install java 21.0.0"
		Then I see "java 21.0.0 is already the current version."
		And I do not see "Setting java 21.0.0 as default."
		And the candidate "java" version "21.0.0" should be the default
		And the exit code is 0

	Scenario: Switch the current version to another installed version
		Given the candidate "java" version "17.0.9" is already installed and default
		And the candidate "java" version "21.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install java 21.0.0"
		Then I see "Setting java 21.0.0 as default."
		And the candidate "java" version "21.0.0" should be the default
		And the candidate "java" version "17.0.9" should not be the default
		And the exit code is 0

	Scenario: Install a candidate that is absent from the candidates cache
		Given the candidate "maven" version "3.9.9" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install maven 3.9.9"
		Then I do not see "Stop! maven is not a valid candidate."
		And I see "Setting maven 3.9.9 as default."
		And the candidate "maven" version "3.9.9" should be the default
		And the exit code is 0

	Scenario: Attempt installing a version that is not present under the candidates folder
		Given the candidate "java" version "21.0.0" is already installed and default
		And the system is bootstrapped
		When I enter "sdk install java 9.9.9"
		Then I see "Stop! java 9.9.9 is not present in"
		And the candidate "java" version "9.9.9" is not installed
		And the candidate "java" version "21.0.0" should be the default
		And the exit code is 1

	Scenario: Attempt installing without providing a version
		Given the candidate "java" version "21.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install java"
		Then I see "No candidate version provided."
		And the candidate "java" version "21.0.0" should not be the default
		And the exit code is 1

	Scenario: Install a local development version from outside the candidates folder
		Given I have a local candidate "groovy" version "2.1-SNAPSHOT" at "/tmp/groovy-core"
		And the system is bootstrapped
		When I enter "sdk install groovy 2.1-SNAPSHOT /tmp/groovy-core"
		Then I see "Linking groovy 2.1-SNAPSHOT to /tmp/groovy-core"
		And the candidate "groovy" version "2.1-SNAPSHOT" is linked to "/tmp/groovy-core"
		And the candidate "groovy" version "2.1-SNAPSHOT" should be the default
		And the exit code is 0

	Scenario: Install does not contact the API even when it is reachable
		Given the candidate "java" version "21.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk install java 21.0.0"
		Then I do not see "Downloading: java 21.0.0"
		And I do not see "is not available"
		And the exit code is 0

	# list

	Scenario: List candidates found under the candidates folder
		Given the candidate "java" version "21.0.0" is already installed and default
		And the candidate "groovy" version "4.0.0" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk list"
		Then I see "Offline: only showing candidates found in"
		And I see "java"
		And I see "21.0.0"
		And I see "groovy"
		And the exit code is 0

	Scenario: List candidate versions found under the candidates folder
		Given the candidate "java" version "21.0.0" is already installed and default
		And the candidate "java" version "17.0.9" is already installed but not default
		And the system is bootstrapped
		When I enter "sdk list java"
		Then I see "Offline: only showing installed java versions"
		And I see "> 21.0.0"
		And I see "* 17.0.9"
		And the exit code is 0

	Scenario: List candidate versions when none are installed
		Given the system is bootstrapped
		When I enter "sdk list java"
		Then I see "Offline: only showing installed java versions"
		And I see "None installed!"
		And the exit code is 0
