from contextlib import contextmanager
import re
import sqlite3
from meal_max.models.battle_model import *; 
from meal_max.models.kitchen_model import *; 
import pytest



@pytest.fixture
def mock_cursor(mocker):
    mock_conn = mocker.Mock()
    mock_cursor = mocker.Mock()

    # Mock the connection's cursor
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = None # Default return for queries
    mock_cursor.fetchall.return_value = []
    mock_conn.commit.return_value = None

# Mock the get_db_connection context manager from sql_utils
    @contextmanager
    def mock_get_db_connection():
        yield mock_conn # Yield the mocked connection object

        mocker.patch('meal_max.models.kitchen_model.get_db_connection', mock_get_db_connection)

        return mock_cursor # Return the mock cursor so we can set expectations per test

@pytest.fixture
def battle_model():
    """Fixture to provide a new instance of BattleModel for each test."""
    return BattleModel()


@pytest.fixture
def mock_update_play_count(mocker):
    """Mock the update_play_count function for testing purposes."""
    return mocker.patch("meal_max.models.battle_model.update_meal_stats")


@pytest.fixture
def sample_meal1():
    return Meal(id=1, meal='Hotpot', price=50.0, cuisine='Chinese', difficulty='MED')

@pytest.fixture
def sample_meal2():
    return Meal(id=2, meal='Sushi', price=12.0, cuisine='Japanese', difficulty='HIGH')

@pytest.fixture
def sample_playlist(sample_food1, sample_food2):
    return [sample_food1, sample_food2]


    
    
    
##################################################
# Add Meal battle Test Cases
##################################################

def test_prep_combatant(battle_model, sample_meal1):
    """Test adding a combatant to the battle."""
    battle_model.prep_combatant(sample_meal1)
    assert len(battle_model.combatants) == 1
    assert battle_model.combatants[0].meal == 'Hotpot'
    
def test_prep_combatant_full_list(battle_model, sample_meal1, sample_meal2):
    """Test error when adding a combatant to a full battle list."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    with pytest.raises(ValueError, match="Combatant list is full, cannot add more combatants."):
        battle_model.prep_combatant(Meal(id=3, meal='Pizza', price=20.0, cuisine='Italian', difficulty='LOW'))

def test_clear_combatants(battle_model, sample_meal1):
    """Test clearing the combatant list."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.clear_combatants()
    assert len(battle_model.combatants) == 0, "Combatants list should be empty after clearing"

def test_battle_winner(battle_model, sample_meal1, sample_meal2, mocker):
    """Test determining the winner of a battle based on score and random number."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    
    # Mock get_random to control the outcome
    mock_get_random = mocker.patch("meal_max.utils.random_utils.get_random")
    winner = battle_model.battle()
    
    # Assert the winner is as expected
    assert winner == sample_meal1.meal
   
def test_not_enough_combatants(battle_model, sample_meal1):
    """Test battle raises an error when there are not enough combatants."""
    battle_model.prep_combatant(sample_meal1)
    with pytest.raises(ValueError, match="Two combatants must be prepped for a battle."):
        battle_model.battle()
        
        
        
##################################################
# Score Calculation Test Cases
##################################################
def test_get_battle_score_Med(battle_model, sample_meal1):
    """Test calculating the battle score for a combatant."""
    score = battle_model.get_battle_score(sample_meal1)
    expected_score = (sample_meal1.price * len(sample_meal1.cuisine)) - 2  # MED difficulty modifier
    assert score == expected_score, f"Expected score to be {expected_score}, but got {score}"

def test_get_battle_score_HRD(battle_model, sample_meal2):
    """Test calculating the battle score for a combatant."""
    score = battle_model.get_battle_score(sample_meal2)
    expected_score = (sample_meal2.price * len(sample_meal2.cuisine)) - 1  # MED difficulty modifier
    assert score == expected_score, f"Expected score to be {expected_score}, but got {score}"

def test_get_combatants(battle_model, sample_meal1, sample_meal2):
    """Test retrieving the list of combatants."""
    battle_model.prep_combatant(sample_meal1)
    battle_model.prep_combatant(sample_meal2)
    combatants = battle_model.get_combatants()
    assert combatants == [sample_meal1, sample_meal2], "Expected combatants list does not match"