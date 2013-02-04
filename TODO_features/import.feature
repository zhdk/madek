# https://www.pivotaltracker.com/story/show/24559683 -> Plupload statt eigenes import-Widget
Feature: Import 
  As a user
  I want to import files to the system
  So that I can share my files with everyone

    
  @poltergeist
	Scenario: Dependencies among the pulldown menus of the copyright field
    When I import several files
     When I go to the import edit
     And I fill in the metadata for entry number 1 as follows:
     | label                           | value                                    |
     | Titel                           | Test image for mass assignment of values |
     | Autor/in                        | Hans Franzfriedrich                      |
     | Datierung                       | 2011-08-09                               |
     | Schlagworte zu Inhalt und Motiv | other                                    |
     | Schlagworte zu Inhalt und Motiv | example                                  |
    Then I can assign the Title to all the other files I just imported
		When I select a copyright status from the predefined ones and this status has values for each of its fields
		And then switch to another copyright status that has no or blank values for any of its fields
		Then each of these fields of the copyright status are cleared
