Feature: Permissions
  As a user
  I want to have different permissions on resources
  So that I can decide who has what kind of access to my data

#Berechtigungen:
#Es gibt folgende Berechtigungen auf Ressourcen im Medienarchiv (In Klammer die deutschen Bezeichnungen des Interfaces):
#- View (Sehen): sehen einer Ressource
#- Edit (Editieren): editieren von Metadaten einer Ressource, hinzufügen und wegnehmen von Ressourcen zu einem Set
#- Download Original (Exportieren des Originals): Exportieren des originalen Files
#- Manage permissions: Verwalten der Berechtigungen auf einer Ressource
#- Ownership: Person, die eine Ressource importiert/erstellt hat, hat defaultmässig die Ownership und alle obigen Berechtigungen.
#- Nennt man eine Person oder eine Gruppe bei den Berechtigungen, wählt für diese aber keine Berechtigungen aus, so bedeutet dies, dass den genannten explizit die Berechtigungen entzogen sind.

# the notion of "ownership" has changed; a resource has an fkey pointing to a
# user, this is what used to be the 'owner' and is now called the 'responsible
# person' in the ui; the term 'owner' is still used in the specifications below

  @transactional_dirty
  Scenario: No permissions
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    And I visit the path of the resource
    Then I am redirected to the main page

  @transactional_dirty
  Scenario: View user-permission lets me view the resource
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And I visit the path of the resource
    Then I see page for the resource

  @transactional_dirty
  Scenario: View group-permission lets me view the resource
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" group-permissions added for me to the resource
    And I visit the path of the resource
    Then I see page for the resource

  @jsbrowser @dirty
  Scenario: Not manage user-permission won't let me edit permissions
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And I visit the path of the resource
    And I open the edit-permissions dialog
    Then I can not edit the permissions

  @jsbrowser @dirty
  Scenario: Manage permission
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And There are "manage" user-permissions added for me to the resource
    And I visit the path of the resource
    And I open the edit-permissions dialog
    Then I can edit the permissions

  @jsbrowser @dirty
  Scenario: No edit user-permission won't let mit edit metadata
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Weitere Aktionen"
    And I click on the link "Metadaten editieren"
    Then I see an error alert
    And I am on the page of the resource

  # test override only once
  @jsbrowser @dirty @wip
  Scenario: No edit user-permission overrides edit user-permission
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    When There are "view" group-permissions added for me to the resource
    When There are "edit" group-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Weitere Aktionen"
    And I click on the link "Metadaten editieren"
    Then I see an error alert
    And I am on the page of the resource


  @jsbrowser @dirty
  Scenario: Edit user-permission will let me edit metadata
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    When There are "edit" user-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Weitere Aktionen"
    And I click on the link "Metadaten editieren"
    And I am on the edit page of the resource
    When I click on the submit button
    Then I am on the page of the resource
    And I see a confirmation alert

  @jsbrowser @dirty 
  Scenario: Edit group-permission will let me edit metadata
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" group-permissions added for me to the resource
    When There are "edit" group-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Weitere Aktionen"
    And I click on the link "Metadaten editieren"
    And I am on the edit page of the resource
    When I click on the submit button
    Then I am on the page of the resource
    And I see a confirmation alert


  @jsbrowser @dirty 
  Scenario: Not the owner / responsible user of a resource 
    Given I am signed-in as "Normin"
    And A resource, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And There are "manage" user-permissions added for me to the resource
    And I visit the path of the resource
    And I open the edit-permissions dialog
    Then I am not the responsible person for that resource

  @jsbrowser 
  Scenario: Owner / responsible user of a resource
    Given I am signed-in as "Normin"
    And A resource owned by me
    And I visit the path of the resource
    And I open the edit-permissions dialog
    Then I am the responsible person for that resource

  @jsbrowser @dirty
  Scenario: No Download permission will not let me download the resource
    Given I am signed-in as "Normin"
    And A media_entry with file, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Exportieren" 
    And I click on the link "Datei ohne Metadaten" inside of the dialog 
    Then There is no link with class "original" in the list with class "download"
    
  @jsbrowser @dirty
  Scenario: Download permission will let me download the resource
    Given I am signed-in as "Normin"
    And A media_entry with file, not owned by normin, and with no permissions whatsoever 
    When There are "view" user-permissions added for me to the resource
    When There are "download" user-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Exportieren" 
    And I click on the link "Datei ohne Metadaten" inside of the dialog 
    Then There is a link with class "original" in the list with class "download"

  @jsbrowser @dirty 
  Scenario: Download permission will let me download the resource
    Given I am signed-in as "Normin"
    And A media_entry with file, not owned by normin, and with no permissions whatsoever 
    When There are "view" group-permissions added for me to the resource
    When There are "download" group-permissions added for me to the resource
    And I visit the path of the resource
    And I click on the link "Exportieren" 
    And I click on the link "Datei ohne Metadaten" inside of the dialog 
    Then There is a link with class "original" in the list with class "download"
    
  @jsbrowser @dirty
  Scenario: Permissions for adding a resource to a set
    Given I am signed-in as "Normin"
    And A media_entry with file, not owned by normin, and with no permissions whatsoever 
    And There are "view" user-permissions added for me to the resource
    And There are "edit" user-permissions added for me to the resource
    Given A set, not owned by normin, and with no permissions whatsoever 
    And The set has no children
    And There are "view" user-permissions added for me to the set
    And There are "edit" user-permissions added for me to the set
    And I visit the path of the resource
    And I click on the link "Weitere Aktionen"
    And I click on the link "Zu Set hinzufügen"
    And I add the resource to the given set 
    Then the resource is in the children of the given set

  




