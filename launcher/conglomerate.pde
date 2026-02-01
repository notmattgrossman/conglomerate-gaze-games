import processing.sound.*;
import java.util.*;

// ============================================================================
// GAME STATE MANAGEMENT
// ============================================================================

enum GameState {
  MENU, GARDEN, CARDS
}

GameState currentState = GameState.MENU;
GameState previousState = GameState.MENU;

// ============================================================================
// MENU VARIABLES
// ============================================================================

PImage menuFlowersImg;
PImage menuCardsImg;
PFont menuFont;
boolean menuInitialized = false;

// Card dimensions and positions for menu
float menuCardWidth = 350;
float menuCardHeight = 500;
float menuCardSpacing = 100;

// Menu hover tracking
long menuHoverStartTime = -1;
boolean menuWasHovering = false;
int menuHoveredCard = -1;  // 0 = garden, 1 = cards, -1 = none
final int menuHoverDuration = 3000;  // 3 seconds
final float menuHoverCircleRadius = 60;

// ============================================================================
// GARDEN GAME VARIABLES (prefixed with garden_)
// ============================================================================

final int garden_rows = 3;
final int garden_cols = 3;
float garden_gameStartTime;
float garden_spacingX, garden_spacingY;
float garden_viewWidth;
float garden_globalScale = 1.0;
PGraphics garden_scene;
ArrayList<ArrayList<Plant>> garden_plants = new ArrayList<ArrayList<Plant>>();
ArrayList<Droplet> garden_droplets = new ArrayList<Droplet>();

PImage garden_potImage;
PImage garden_stemImage;
PImage garden_backgroundImage;
PImage[] garden_flowerImages = new PImage[3];
PFont garden_font;

float garden_canRotation = 0;
final float garden_growTime = 5000;

SoundFile garden_backgroundSound;
SoundFile garden_waterSound;
SoundFile[] garden_twinkleSounds = new SoundFile[3];
float garden_waterVolumeTarget = 0;
float garden_waterVolumeLevel = 0;
boolean garden_waterSoundPlaying = false;
final float garden_waterFadeSpeed = 0.02f;
boolean garden_initialized = false;

// ============================================================================
// CARDS GAME VARIABLES (prefixed with cards_)
// ============================================================================

final int cards_COLS = 3;
final int cards_ROWS = 4;

final float cards_DESIGN_WIDTH = 800f;
final float cards_DESIGN_HEIGHT = 480f;
final float cards_BASE_CARD_WIDTH = 110f;
final float cards_BASE_CARD_HEIGHT = 166f;
final float cards_BASE_CARD_SPACING_X = 114f;
final float cards_BASE_CARD_SPACING_Y = 24f;
final float cards_BASE_HOVER_CIRCLE_RADIUS = 40f;
final float cards_PADDING_X_RATIO = 0.15f;
final float cards_PADDING_Y_RATIO = 0.12f;

final int cards_FILL_DURATION = 5000;
final int cards_FLIP_DURATION = 300;
final int cards_MISMATCH_DURATION = 1500;

PImage cards_bgImage;
PImage cards_blueCard;
PImage cards_redCard;
PImage[] cards_cardVariants;
int[][] cards_cardAssignments;
PFont cards_monoFont;
SoundFile cards_flipSound;
SoundFile cards_fanfareSound;

PGraphics cards_scene;
float cards_viewWidth = 0;
float cards_viewHeight = 0;

float cards_layoutScale = 1f;
float cards_cardWidth = cards_BASE_CARD_WIDTH;
float cards_cardHeight = cards_BASE_CARD_HEIGHT;
float cards_cardSpacingX = cards_BASE_CARD_SPACING_X;
float cards_cardSpacingY = cards_BASE_CARD_SPACING_Y;
float cards_hoverCircleRadius = cards_BASE_HOVER_CIRCLE_RADIUS;
float cards_paddingX = 0;
float cards_paddingY = 0;
float cards_totalGridWidth = 0;
float cards_totalGridHeight = 0;
float cards_startX = 0;
float cards_startY = 0;

ArrayList<FlippedCard> cards_flippedCards = new ArrayList<FlippedCard>();
ArrayList<FlippingCard> cards_flippingCards = new ArrayList<FlippingCard>();
ArrayList<CardPos> cards_matchedCards = new ArrayList<CardPos>();
ArrayList<ConfettiParticle> cards_confettiParticles = new ArrayList<ConfettiParticle>();

long cards_hoverStartTime = -1;
boolean cards_wasHovering = false;
int cards_hoveredCardRow = -1;
int cards_hoveredCardCol = -1;
long cards_mismatchStartTime = -1;
long cards_gameStartTime = -1;
int cards_totalFlips = 0;

String[] cards_CARD_VARIANT_NAMES = {
  "brain",
  "diamond",
  "fire",
  "fish",
  "football",
  "money"
};

boolean cards_initialized = false;

// ============================================================================
// MAIN SETUP AND DRAW
// ============================================================================

void settings() {
  size(1200, 600);
  pixelDensity(2);
}

void setup() {
  surface.setTitle("Z-Lab OCT Games");
  surface.setResizable(true);
  
  // Initialize menu with proper font
  menuFont = createFont("Arial", 48, true);
  
  // Load menu images from data folder
  try {
    menuFlowersImg = loadImage("flowers.png");
    menuCardsImg = loadImage("cards.png");
    
    if (menuFlowersImg == null || menuCardsImg == null) {
      println("ERROR: Menu images not found in data folder");
      println("Looking for: " + dataPath("flowers.png"));
      println("Looking for: " + dataPath("cards.png"));
    }
  } catch (Exception e) {
    println("Error loading menu images: " + e);
  }
  
  menuInitialized = true;
}

void draw() {
  switch (currentState) {
    case MENU:
      drawMenu();
      break;
    case GARDEN:
      if (!garden_initialized) {
        initializeGarden();
      }
      drawGarden();
      break;
    case CARDS:
      if (!cards_initialized) {
        initializeCards();
      }
      drawCards();
      break;
  }
}

void keyPressed() {
  if (key == ESC) {
    key = 0; // Prevent window from closing
    if (currentState != GameState.MENU) {
      returnToMenu();
    }
  }
}

void mousePressed() {
  // Mouse press no longer needed for menu selection
}

// ============================================================================
// MENU FUNCTIONS
// ============================================================================

void drawMenu() {
  background(0);
  
  // Title
  textFont(menuFont);
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(60);
  text("Choose your game!", width / 2, 100);
  
  // Calculate card positions
  float totalWidth = menuCardWidth * 2 + menuCardSpacing;
  float startX = (width - totalWidth) / 2;
  float cardY = (height - menuCardHeight) / 2 + 50;
  
  // Left card (Garden)
  float leftCardX = startX;
  boolean hoveringLeft = drawMenuCard(leftCardX, cardY, menuCardWidth, menuCardHeight, menuFlowersImg, "Water the Plants", 0);
  
  // Right card (Cards)
  float rightCardX = startX + menuCardWidth + menuCardSpacing;
  boolean hoveringRight = drawMenuCard(rightCardX, cardY, menuCardWidth, menuCardHeight, menuCardsImg, "Memory Match", 1);
  
  // Determine which card is being hovered
  int currentHoveredCard = -1;
  if (hoveringLeft) {
    currentHoveredCard = 0;
  } else if (hoveringRight) {
    currentHoveredCard = 1;
  }
  
  // Handle hover timing
  if (currentHoveredCard >= 0) {
    noCursor();
    boolean sameCard = (menuHoveredCard == currentHoveredCard);
    if (!menuWasHovering || !sameCard) {
      menuHoverStartTime = millis();
      menuHoveredCard = currentHoveredCard;
    }
    float elapsed = millis() - menuHoverStartTime;
    float fillProgress = constrain(elapsed / menuHoverDuration, 0, 1);
    
    // Get card center position
    float cardCenterX = (currentHoveredCard == 0) ? (leftCardX + menuCardWidth / 2) : (rightCardX + menuCardWidth / 2);
    float cardCenterY = cardY + menuCardHeight / 2;
    
    // Draw hover indicator
    stroke(255, 200);
    strokeWeight(3);
    noFill();
    ellipse(cardCenterX, cardCenterY, menuHoverCircleRadius * 2, menuHoverCircleRadius * 2);
    
    if (fillProgress > 0) {
      noStroke();
      fill(255, 150);
      float innerRadius = menuHoverCircleRadius * (1 - fillProgress);
      ellipse(cardCenterX, cardCenterY, max(innerRadius * 2, 2), max(innerRadius * 2, 2));
    }
    
    // Trigger selection when filled
    if (fillProgress >= 1) {
      if (menuHoveredCard == 0) {
        currentState = GameState.GARDEN;
      } else {
        currentState = GameState.CARDS;
      }
      menuResetHover();
    } else {
      menuWasHovering = true;
    }
  } else {
    cursor();
    menuResetHover();
  }
}

boolean drawMenuCard(float x, float y, float w, float h, PImage img, String label, int cardIndex) {
  boolean isHovered = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  
  // Draw card background
  noFill();
  stroke(255);
  strokeWeight(isHovered ? 6 : 3);
  rectMode(CORNER);
  rect(x, y, w, h, 20);
  
  // Draw image if loaded
  if (img != null) {
    imageMode(CENTER);
    float imgSize = min(w, h) * 0.7;
    image(img, x + w/2, y + h/2 - 30, imgSize * img.width / img.height, imgSize);
  } else {
    // Draw placeholder if image failed to load
    fill(50);
    rectMode(CORNER);
    rect(x + 20, y + 20, w - 40, h - 100, 10);
    fill(255);
    textSize(24);
    text("Preview\nUnavailable", x + w/2, y + h/2 - 30);
  }
  
  // Draw label
  textAlign(CENTER, CENTER);
  textSize(28);
  fill(255);
  text(label, x + w/2, y + h - 40);
  
  return isHovered;
}

void menuResetHover() {
  menuHoverStartTime = -1;
  menuHoveredCard = -1;
  menuWasHovering = false;
}

void returnToMenu() {
  // Clean up current game
  if (currentState == GameState.GARDEN) {
    cleanupGarden();
  } else if (currentState == GameState.CARDS) {
    cleanupCards();
  }
  
  currentState = GameState.MENU;
  cursor(ARROW);
}

// ============================================================================
// GARDEN GAME FUNCTIONS
// ============================================================================

void initializeGarden() {
  garden_viewWidth = width / 2.0f;
  garden_scene = createGraphics(int(garden_viewWidth), height);
  garden_gameStartTime = millis();
  
  // Load assets
  try {
    garden_potImage = loadImage("img/pot.png");
    garden_stemImage = loadImage("img/stem.png");
    garden_backgroundImage = loadImage("img/background.jpg");
    garden_flowerImages[0] = loadImage("img/sunflower.png");
    garden_flowerImages[1] = loadImage("img/pinkflower.png");
    garden_flowerImages[2] = loadImage("img/blueflower.png");
  } catch (Exception e) {
    println("Error loading garden images: " + e);
  }
  
  garden_font = createFont("Arial", 14);
  
  garden_spacingX = garden_viewWidth / (garden_cols + 1f);
  garden_spacingY = height / (garden_rows + 1f);
  
  // Initialize plants
  garden_plants.clear();
  for (int r = 0; r < garden_rows; r++) {
    ArrayList<Plant> row = new ArrayList<Plant>();
    garden_plants.add(row);
    for (int c = 0; c < garden_cols; c++) {
      float x = (c + 1) * garden_spacingX;
      float y = (r + 1) * garden_spacingY;
      row.add(new Plant(x, y, r, c));
    }
  }
  
  // Audio setup
  try {
    garden_backgroundSound = new SoundFile(this, dataPath("garden-sfx/background.mp3"));
    garden_backgroundSound.loop();
    garden_backgroundSound.amp(0.35f);
    
    garden_waterSound = new SoundFile(this, dataPath("garden-sfx/water.mp3"));
    garden_waterSound.loop();
    garden_waterSound.amp(0);
    
    garden_twinkleSounds[0] = new SoundFile(this, dataPath("garden-sfx/twinkle.mp3"));
    garden_twinkleSounds[1] = new SoundFile(this, dataPath("garden-sfx/twinkle-1.mp3"));
    garden_twinkleSounds[2] = new SoundFile(this, dataPath("garden-sfx/twinkle-2.mp3"));
  } catch (Exception e) {
    println("Garden audio setup failed: " + e);
  }
  
  garden_initialized = true;
}

void drawGarden() {
  garden_viewWidth = width / 2.0f;
  int newSceneW = max(1, int(garden_viewWidth));
  int newSceneH = max(1, height);
  
  garden_globalScale = min(garden_viewWidth / 960.0f, height / 1080.0f);
  
  if (garden_scene == null || garden_scene.width != newSceneW || garden_scene.height != newSceneH) {
    garden_scene = createGraphics(newSceneW, newSceneH);
  }
  
  float logicalMX = mouseX % garden_viewWidth;
  logicalMX = constrain(logicalMX, 0, garden_viewWidth);
  float logicalMY = mouseY;
  
  int fullyGrown = garden_updateState(logicalMX, logicalMY);
  
  garden_scene.beginDraw();
  garden_renderScene(garden_scene, logicalMX, logicalMY, fullyGrown);
  garden_scene.endDraw();
  
  imageMode(CORNER);
  image(garden_scene, 0, 0);
  image(garden_scene, garden_viewWidth, 0);
}

int garden_updateState(float mx, float my) {
  boolean isWatering = false;
  int fullyGrown = 0;
  
  Plant targetPlant = null;
  float minDist = Float.MAX_VALUE;
  
  float spoutLogicalX = mx + 38 + cos(radians(-20)) * 60;
  float spoutLogicalY = my - 8 + sin(radians(-20)) * 60;
  
  for (ArrayList<Plant> row : garden_plants) {
    for (Plant plant : row) {
      if (abs(mx - plant.x) < 35) {
        if (abs(my - plant.y) < 35) {
          float d = dist(mx, my, plant.x, plant.y);
          if (d < minDist) {
            minDist = d;
            targetPlant = plant;
          }
        }
      }
    }
  }
  
  for (ArrayList<Plant> row : garden_plants) {
    for (Plant plant : row) {
      boolean active = (plant == targetPlant);
      plant.update(active);
      
      if (plant.growth >= 1) {
        fullyGrown++;
      }
      
      if (plant.watering) {
        isWatering = true;
        if (random(1) < 0.3f) {
          PVector spout = garden_getSpoutPosition(mx, my);
          garden_droplets.add(new Droplet(spout.x, spout.y, plant));
        }
      }
    }
  }
  
  float targetRotation = isWatering ? 33 : 0;
  garden_canRotation = lerp(garden_canRotation, targetRotation, 0.15f);
  
  for (int i = garden_droplets.size() - 1; i >= 0; i--) {
    Droplet d = garden_droplets.get(i);
    d.update();
    if (d.shouldRemove()) {
      garden_droplets.remove(i);
    }
  }
  
  garden_updateWaterSound(isWatering);
  garden_processWaterFade();
  return fullyGrown;
}

void garden_renderScene(PGraphics pg, float mx, float my, int fullyGrown) {
  if (garden_backgroundImage != null) {
    float bgAspect = (float)garden_backgroundImage.width / garden_backgroundImage.height;
    float viewAspect = (float)pg.width / pg.height;
    
    pg.imageMode(CORNER);
    if (viewAspect > bgAspect) {
      float drawHeight = pg.width / bgAspect;
      float yOffset = (pg.height - drawHeight) / 2;
      pg.image(garden_backgroundImage, 0, yOffset, pg.width, drawHeight);
    } else {
      float drawWidth = pg.height * bgAspect;
      float xOffset = (pg.width - drawWidth) / 2;
      pg.image(garden_backgroundImage, xOffset, 0, drawWidth, pg.height);
    }
  } else {
    pg.noStroke();
    pg.fill(220, 245, 255);
    pg.rect(0, 0, pg.width, pg.height);
  }
  
  pg.fill(30, 80, 180, 43);
  pg.noStroke();
  pg.rect(0, 0, pg.width, pg.height);
  
  for (ArrayList<Plant> row : garden_plants) {
    for (Plant plant : row) {
      plant.display(pg, garden_globalScale);
    }
  }
  
  for (Droplet d : garden_droplets) {
    d.display(pg, garden_globalScale);
  }
  
  garden_drawCan(pg, mx - 85 * garden_globalScale, my - 85 * garden_globalScale, garden_globalScale);
  garden_drawHud(pg, fullyGrown);
}

void garden_updateWaterSound(boolean pouring) {
  if (garden_waterSound == null) return;
  
  garden_waterVolumeTarget = pouring ? 0.55f : 0;
  if (pouring && !garden_waterSoundPlaying) {
    garden_waterVolumeLevel = 0;
    garden_waterSound.amp(0);
    garden_waterSound.play();
    garden_waterSoundPlaying = true;
  }
}

void garden_processWaterFade() {
  if (garden_waterSound == null) return;
  if (!garden_waterSoundPlaying && garden_waterVolumeLevel == 0 && garden_waterVolumeTarget == 0) {
    return;
  }
  
  if (abs(garden_waterVolumeLevel - garden_waterVolumeTarget) <= garden_waterFadeSpeed) {
    garden_waterVolumeLevel = garden_waterVolumeTarget;
  } else if (garden_waterVolumeLevel < garden_waterVolumeTarget) {
    garden_waterVolumeLevel += garden_waterFadeSpeed;
  } else {
    garden_waterVolumeLevel -= garden_waterFadeSpeed;
  }
  
  garden_waterVolumeLevel = constrain(garden_waterVolumeLevel, 0, 0.55f);
  garden_waterSound.amp(garden_waterVolumeLevel);
  
  if (garden_waterVolumeTarget == 0 && garden_waterVolumeLevel == 0 && garden_waterSoundPlaying) {
    garden_waterSound.stop();
    garden_waterSoundPlaying = false;
  }
}

void garden_drawHud(PGraphics pg, int fullyGrown) {
  float bannerHeight = 35;
  pg.fill(144, 238, 144);
  pg.noStroke();
  pg.rect(0, pg.height - bannerHeight, pg.width, bannerHeight);
  
  pg.fill(0, 100, 0);
  pg.textAlign(LEFT, CENTER);
  pg.textSize(14);
  pg.text("Flowers: " + fullyGrown + " / 9", 20, pg.height - bannerHeight / 2);
  
  pg.textAlign(CENTER, CENTER);
  pg.text("Water the plants to see the flowers bloom!", pg.width / 2, pg.height - bannerHeight / 2);
  
  int minutes = floor((millis() - garden_gameStartTime) / 60000);
  int seconds = floor(((millis() - garden_gameStartTime) % 60000) / 1000);
  String timeString = nf(minutes, 0) + ":" + nf(seconds, 2);
  pg.textAlign(RIGHT, CENTER);
  pg.text(timeString, pg.width - 20, pg.height - bannerHeight / 2);
}

PVector garden_getSpoutPosition(float canX, float canY) {
  float spoutBaseX = 38 * garden_globalScale;
  float spoutBaseY = -8 * garden_globalScale;
  float spoutAngle = radians(-20);
  float spoutLength = 60 * garden_globalScale;
  float spoutTipX = spoutBaseX + cos(spoutAngle) * spoutLength;
  float spoutTipY = spoutBaseY + sin(spoutAngle) * spoutLength;
  float canAngle = radians(garden_canRotation);
  float rotatedX = spoutTipX * cos(canAngle) - spoutTipY * sin(canAngle);
  float rotatedY = spoutTipX * sin(canAngle) + spoutTipY * cos(canAngle);
  return new PVector(canX + rotatedX, canY + rotatedY);
}

void garden_drawCan(PGraphics pg, float x, float y, float scale) {
  pg.pushMatrix();
  pg.translate(x, y);
  pg.scale(scale);
  pg.rotate(radians(garden_canRotation));
  pg.noStroke();
  pg.fill(60, 170, 255);
  pg.rect(-33, -15, 68, 75);
  pg.fill(90, 190, 255);
  pg.ellipse(0, -15, 68, 23);
  pg.noFill();
  pg.stroke(60, 170, 255);
  pg.strokeWeight(9);
  pg.arc(0, -15, 60, 105, PI, TWO_PI);
  pg.noStroke();
  pg.fill(60, 170, 255);
  pg.pushMatrix();
  pg.translate(38, -8);
  pg.rotate(radians(-20));
  pg.rect(-15, 0, 60, 15, 5);
  pg.quad(38, 15, 53, 23, 53, -8, 38, 0);
  pg.popMatrix();
  pg.popMatrix();
}

void cleanupGarden() {
  if (garden_backgroundSound != null) {
    garden_backgroundSound.stop();
  }
  if (garden_waterSound != null) {
    garden_waterSound.stop();
  }
  garden_initialized = false;
  garden_plants.clear();
  garden_droplets.clear();
}

void garden_windowResized() {
  garden_viewWidth = width / 2.0f;
  garden_spacingX = garden_viewWidth / (garden_cols + 1f);
  garden_spacingY = height / (garden_rows + 1f);
  
  for (ArrayList<Plant> row : garden_plants) {
    for (Plant plant : row) {
      plant.x = (plant.col + 1) * garden_spacingX;
      plant.y = (plant.row + 1) * garden_spacingY;
    }
  }
}

// ============================================================================
// GARDEN GAME CLASSES
// ============================================================================

class Plant {
  float x, y;
  int row, col;
  boolean watering;
  float growth;
  float startTime;
  boolean twinklePlayed;
  int flowerIndex;
  
  Plant(float x, float y, int row, int col) {
    this.x = x;
    this.y = y;
    this.row = row;
    this.col = col;
    this.flowerIndex = (row * 2 + col) % garden_flowerImages.length;
  }
  
  void update(boolean isBeingWatered) {
    if (isBeingWatered) {
      if (growth >= 1) {
        watering = false;
        return;
      }
      if (!watering) {
        watering = true;
        startTime = millis();
        growth = 0;
        twinklePlayed = false;
      }
      growth = constrain((millis() - startTime) / garden_growTime, 0, 1);
      if (growth >= 1 && !twinklePlayed) {
        garden_playTwinkleSound(flowerIndex);
        twinklePlayed = true;
      }
    } else {
      watering = false;
    }
  }
  
  void display(PGraphics pg, float scale) {
    pg.pushMatrix();
    pg.translate(x, y);
    pg.scale(scale);
    float stemStartY = -25;
    float maxStemHeight = 80;
    
    if (garden_stemImage != null) {
      float stemRatio = (float)garden_stemImage.width / garden_stemImage.height;
      float fixedStemHeight = 80;
      float fixedStemWidth = fixedStemHeight * stemRatio * 1.1f;
      
      float flowerCenterY = 0;
      if (growth > 0) {
        float currentStemHeight = maxStemHeight * growth;
        flowerCenterY = stemStartY - currentStemHeight;
      }
      if (growth > 0) {
        float potBottomY = 40;
        float stemBottomY = flowerCenterY + fixedStemHeight;
        float visibleHeight = fixedStemHeight;
        if (stemBottomY > potBottomY) {
          visibleHeight = potBottomY - flowerCenterY;
          int sourceVisibleHeight = (int)((visibleHeight / fixedStemHeight) * garden_stemImage.height);
          
          pg.imageMode(CORNER);
          pg.image(garden_stemImage, -fixedStemWidth / 2, flowerCenterY, fixedStemWidth, visibleHeight, 0, 0, garden_stemImage.width, sourceVisibleHeight);
        } else {
          pg.imageMode(CORNER);
          pg.image(garden_stemImage, -fixedStemWidth / 2, flowerCenterY, fixedStemWidth, fixedStemHeight);
        }
        pg.imageMode(CENTER);
        float maxSize = (flowerIndex == 2) ? 90 : 72;
        float baseSize = 24 + ((maxSize - 24) * growth);
        PImage flower = garden_flowerImages[flowerIndex];
        if (flower != null) {
          float aspectRatio = (float)flower.width / flower.height;
          float flowerWidth, flowerHeight;
          if (aspectRatio > 1) {
            flowerWidth = baseSize;
            flowerHeight = baseSize / aspectRatio;
          } else {
            flowerHeight = baseSize;
            flowerWidth = baseSize * aspectRatio;
          }
          pg.image(flower, 0, flowerCenterY, flowerWidth, flowerHeight);
        }
      }
    }
    pg.imageMode(CENTER);
    
    if (garden_potImage != null) {
      float potMaxDim = 70;
      float potRatio = (float)garden_potImage.width / garden_potImage.height;
      float potW, potH;
      if (potRatio > 1) {
        potW = potMaxDim;
        potH = potMaxDim / potRatio;
      } else {
        potH = potMaxDim;
        potW = potMaxDim * potRatio;
      }
      
      pg.tint(0, 0, 0, 100);
      pg.image(garden_potImage, 2, 8, potW, potH);
      pg.noTint();
      pg.image(garden_potImage, 0, 5, potW, potH);
    }
    pg.popMatrix();
  }
}

class Droplet {
  float x, y;
  float speed;
  float len;
  float targetY;
  boolean done = false;
  
  Droplet(float x, float y, Plant plant) {
    this.x = x + random(-8, 8);
    this.y = y + random(-8, 8);
    this.speed = random(4, 8);
    this.len = random(8, 15);
    this.targetY = (plant != null) ? plant.y - 30 : height + len;
  }
  
  void update() {
    if (done) {
      return;
    }
    y += speed;
    if (y + len >= targetY) {
      y = targetY - len;
      done = true;
    }
  }
  
  void display(PGraphics pg, float scale) {
    pg.stroke(0, 120, 255);
    pg.strokeWeight(3 * scale);
    pg.line(x, y, x, y + len * scale);
  }
  
  boolean shouldRemove() {
    return done || y > height + len;
  }
}

void garden_playTwinkleSound(int index) {
  if (garden_twinkleSounds[0] == null) {
    return;
  }
  int source = index % garden_twinkleSounds.length;
  SoundFile clip = garden_twinkleSounds[source];
  if (clip != null) {
    clip.play();
  }
}

// ============================================================================
// CARDS GAME FUNCTIONS
// ============================================================================

void initializeCards() {
  cards_viewWidth = width / 2.0f;
  cards_viewHeight = height;
  
  try {
    cards_bgImage = loadImage("backrgound.png");
    cards_blueCard = loadImage("bluecard.png");
    cards_redCard = loadImage("redcard.png");
    
    cards_cardVariants = new PImage[cards_CARD_VARIANT_NAMES.length];
    for (int i = 0; i < cards_CARD_VARIANT_NAMES.length; i++) {
      cards_cardVariants[i] = loadImage(cards_CARD_VARIANT_NAMES[i] + ".png");
    }
  } catch (Exception e) {
    println("Error loading card images: " + e);
  }
  
  cards_cardAssignments = new int[cards_ROWS][cards_COLS];
  cards_initializeCardAssignments();
  
  cards_monoFont = createFont("Courier", 12, true);
  
  try {
    cards_flipSound = new SoundFile(this, "cardflip.mp3");
    cards_fanfareSound = new SoundFile(this, "fanfare.mp3");
  } catch (Exception e) {
    println("Error loading card sounds: " + e);
  }
  
  cards_gameStartTime = millis();
  cards_initialized = true;
}

void drawCards() {
  cards_viewWidth = width / 2.0f;
  cards_viewHeight = height;
  
  int newSceneW = max(1, int(cards_viewWidth));
  int newSceneH = max(1, int(cards_viewHeight));
  if (cards_scene == null || cards_scene.width != newSceneW || cards_scene.height != newSceneH) {
    cards_scene = createGraphics(newSceneW, newSceneH);
  }
  
  cards_updateLayoutMetrics();
  
  float logicalMX = mouseX % cards_viewWidth;
  logicalMX = constrain(logicalMX, 0, cards_viewWidth);
  float logicalMY = constrain(mouseY, 0, cards_viewHeight);
  
  cards_scene.beginDraw();
  
  if (cards_bgImage != null) {
    cards_scene.image(cards_bgImage, 0, 0, cards_viewWidth, cards_viewHeight);
  } else {
    cards_scene.background(50, 100, 50);
  }
  
  boolean isHoveringCard = false;
  int currentHoveredRow = -1;
  int currentHoveredCol = -1;
  
  if (cards_mismatchStartTime >= 0 && cards_flippedCards.size() == 2) {
    if (millis() - cards_mismatchStartTime >= cards_MISMATCH_DURATION) {
      FlippedCard card1 = cards_flippedCards.get(0);
      FlippedCard card2 = cards_flippedCards.get(1);
      
      cards_flippingCards.add(new FlippingCard(card1.row, card1.col, millis(), true));
      cards_playFlipSound();
      cards_flippingCards.add(new FlippingCard(card2.row, card2.col, millis(), true));
      cards_playFlipSound();
      
      cards_flippedCards.clear();
      cards_mismatchStartTime = -1;
    }
  }
  
  for (int row = 0; row < cards_ROWS; row++) {
    for (int col = 0; col < cards_COLS; col++) {
      float x = cards_cardXForCol(col);
      float y = cards_cardYForRow(row);
      boolean matched = cards_isMatched(row, col);
      boolean currentlyFlipped = cards_isCurrentlyFlipped(row, col);
      FlippingCard flippingCard = cards_getFlippingCard(row, col);
      
      if (cards_isMouseOverCard(logicalMX, logicalMY, x, y) &&
          !matched &&
          flippingCard == null &&
          !currentlyFlipped &&
          cards_flippedCards.size() < 2) {
        isHoveringCard = true;
        currentHoveredRow = row;
        currentHoveredCol = col;
      }
      
      if (flippingCard != null) {
        float flipElapsed = millis() - flippingCard.startTime;
        float rawProgress = constrain(flipElapsed / cards_FLIP_DURATION, 0, 1);
        float flipProgress = cards_bezierEase(rawProgress);
        float scaleX;
        boolean showFlipped;
        
        if (flippingCard.isFlippingBack) {
          if (flipProgress < 0.5f) {
            scaleX = 1 - (flipProgress * 2);
            showFlipped = true;
          } else {
            scaleX = (flipProgress - 0.5f) * 2;
            showFlipped = false;
          }
        } else {
          if (flipProgress < 0.5f) {
            scaleX = 1 - (flipProgress * 2);
            showFlipped = false;
          } else {
            scaleX = (flipProgress - 0.5f) * 2;
            showFlipped = true;
          }
        }
        
        cards_scene.pushMatrix();
        cards_scene.translate(x + cards_cardWidth / 2f, y + cards_cardHeight / 2f);
        cards_scene.scale(max(scaleX, 0.001f), 1);
        
        if (showFlipped) {
          int variantIndex = cards_cardAssignments[row][col];
          if (cards_cardVariants[variantIndex] != null) {
            cards_scene.image(cards_cardVariants[variantIndex], -cards_cardWidth / 2f, -cards_cardHeight / 2f, cards_cardWidth, cards_cardHeight);
          }
        } else {
          boolean isBlue = (row + col) % 2 == 0;
          PImage cardImage = isBlue ? cards_blueCard : cards_redCard;
          if (cardImage != null) {
            cards_scene.image(cardImage, -cards_cardWidth / 2f, -cards_cardHeight / 2f, cards_cardWidth, cards_cardHeight);
          }
        }
        cards_scene.popMatrix();
        
        if (flipProgress >= 1) {
          if (flippingCard.isFlippingBack) {
            cards_removeFromFlipped(row, col);
          } else {
            int variantIndex = cards_cardAssignments[row][col];
            cards_flippedCards.add(new FlippedCard(row, col, variantIndex));
            cards_totalFlips++;
            
            if (cards_flippedCards.size() == 2) {
              FlippedCard card1 = cards_flippedCards.get(0);
              FlippedCard card2 = cards_flippedCards.get(1);
              if (card1.variantIndex == card2.variantIndex) {
                cards_matchedCards.add(new CardPos(card1.row, card1.col));
                cards_matchedCards.add(new CardPos(card2.row, card2.col));
                
                float card1X = cards_cardCenterX(card1.col);
                float card1Y = cards_cardCenterY(card1.row);
                float card2X = cards_cardCenterX(card2.col);
                float card2Y = cards_cardCenterY(card2.row);
                cards_createConfetti(card1X, card1Y);
                cards_createConfetti(card2X, card2Y);
                cards_playFanfare();
                cards_flippedCards.clear();
              } else {
                cards_mismatchStartTime = millis();
              }
            }
          }
          cards_flippingCards.remove(flippingCard);
        }
      } else if (matched) {
        int variantIndex = cards_cardAssignments[row][col];
        if (cards_cardVariants[variantIndex] != null) {
          cards_scene.image(cards_cardVariants[variantIndex], x, y, cards_cardWidth, cards_cardHeight);
        }
        cards_scene.noStroke();
        cards_scene.fill(0, 128);
        cards_scene.rect(x, y, cards_cardWidth, cards_cardHeight);
      } else if (currentlyFlipped) {
        int variantIndex = cards_cardAssignments[row][col];
        if (cards_cardVariants[variantIndex] != null) {
          cards_scene.image(cards_cardVariants[variantIndex], x, y, cards_cardWidth, cards_cardHeight);
        }
      } else {
        boolean isBlue = (row + col) % 2 == 0;
        PImage cardImage = isBlue ? cards_blueCard : cards_redCard;
        if (cardImage != null) {
          cards_scene.image(cardImage, x, y, cards_cardWidth, cards_cardHeight);
        }
      }
    }
  }
  
  if (isHoveringCard && currentHoveredRow >= 0 && currentHoveredCol >= 0) {
    noCursor();
    boolean sameCard = (cards_hoveredCardRow == currentHoveredRow && cards_hoveredCardCol == currentHoveredCol);
    if (!cards_wasHovering || !sameCard) {
      cards_hoverStartTime = millis();
      cards_hoveredCardRow = currentHoveredRow;
      cards_hoveredCardCol = currentHoveredCol;
    }
    float elapsed = millis() - cards_hoverStartTime;
    float fillProgress = constrain(elapsed / cards_FILL_DURATION, 0, 1);
    float cardX = cards_cardCenterX(currentHoveredCol);
    float cardY = cards_cardCenterY(currentHoveredRow);
    
    cards_scene.stroke(255, 200);
    cards_scene.strokeWeight(2);
    cards_scene.noFill();
    cards_scene.ellipse(cardX, cardY, cards_hoverCircleRadius * 2, cards_hoverCircleRadius * 2);
    
    if (fillProgress > 0) {
      cards_scene.noStroke();
      cards_scene.fill(255, 150);
      float innerRadius = cards_hoverCircleRadius * (1 - fillProgress);
      cards_scene.ellipse(cardX, cardY, max(innerRadius * 2, 2), max(innerRadius * 2, 2));
    }
    
    if (fillProgress >= 1) {
      if (!cards_isCurrentlyFlipped(cards_hoveredCardRow, cards_hoveredCardCol) &&
          cards_getFlippingCard(cards_hoveredCardRow, cards_hoveredCardCol) == null &&
          !cards_isMatched(cards_hoveredCardRow, cards_hoveredCardCol) &&
          cards_flippedCards.size() < 2) {
        cards_flippingCards.add(new FlippingCard(cards_hoveredCardRow, cards_hoveredCardCol, millis(), false));
        cards_playFlipSound();
      }
      cards_resetHover();
    } else {
      cards_wasHovering = true;
    }
  } else {
    cursor();
    cards_resetHover();
  }
  
  for (int i = cards_confettiParticles.size() - 1; i >= 0; i--) {
    ConfettiParticle particle = cards_confettiParticles.get(i);
    particle.update();
    particle.draw(cards_scene);
    if (particle.isDead()) {
      cards_confettiParticles.remove(i);
    }
  }
  
  cards_scene.endDraw();
  
  imageMode(CORNER);
  image(cards_scene, 0, 0);
  image(cards_scene, cards_viewWidth, 0);
}

void cards_updateLayoutMetrics() {
  // Calculate padding first
  cards_paddingX = cards_viewWidth * cards_PADDING_X_RATIO;
  cards_paddingY = cards_viewHeight * cards_PADDING_Y_RATIO;
  
  // Calculate available space after padding
  float availableWidth = cards_viewWidth - cards_paddingX * 2f;
  float availableHeight = cards_viewHeight - cards_paddingY * 2f;
  
  // Calculate what size the grid would be at different scales
  float baseGridWidth = (cards_BASE_CARD_WIDTH * cards_COLS) + (cards_BASE_CARD_SPACING_X * (cards_COLS - 1));
  float baseGridHeight = (cards_BASE_CARD_HEIGHT * cards_ROWS) + (cards_BASE_CARD_SPACING_Y * (cards_ROWS - 1));
  
  // Calculate scale needed to fit within available space
  float scaleToFitWidth = availableWidth / baseGridWidth;
  float scaleToFitHeight = availableHeight / baseGridHeight;
  
  // Use the smaller scale to ensure everything fits
  cards_layoutScale = min(scaleToFitWidth, scaleToFitHeight);
  
  // Apply scale to all dimensions
  cards_cardWidth = cards_BASE_CARD_WIDTH * cards_layoutScale;
  cards_cardHeight = cards_BASE_CARD_HEIGHT * cards_layoutScale;
  cards_cardSpacingX = cards_BASE_CARD_SPACING_X * cards_layoutScale;
  cards_cardSpacingY = cards_BASE_CARD_SPACING_Y * cards_layoutScale;
  cards_hoverCircleRadius = cards_BASE_HOVER_CIRCLE_RADIUS * cards_layoutScale;
  
  // Calculate actual grid size
  cards_totalGridWidth = (cards_cardWidth * cards_COLS) + (cards_cardSpacingX * (cards_COLS - 1));
  cards_totalGridHeight = (cards_cardHeight * cards_ROWS) + (cards_cardSpacingY * (cards_ROWS - 1));
  
  // Center the grid in available space
  float offsetX = (availableWidth - cards_totalGridWidth) / 2f;
  float offsetY = (availableHeight - cards_totalGridHeight) / 2f;
  
  cards_startX = cards_paddingX + offsetX;
  cards_startY = cards_paddingY + offsetY;
}

float cards_cardXForCol(int col) {
  return cards_startX + col * (cards_cardWidth + cards_cardSpacingX);
}

float cards_cardYForRow(int row) {
  return cards_startY + row * (cards_cardHeight + cards_cardSpacingY);
}

float cards_cardCenterX(int col) {
  return cards_cardXForCol(col) + cards_cardWidth / 2f;
}

float cards_cardCenterY(int row) {
  return cards_cardYForRow(row) + cards_cardHeight / 2f;
}

void cards_resetHover() {
  cards_hoverStartTime = -1;
  cards_hoveredCardRow = -1;
  cards_hoveredCardCol = -1;
  cards_wasHovering = false;
}

boolean cards_isMouseOverCard(float mx, float my, float x, float y) {
  return mx >= x && mx <= x + cards_cardWidth && my >= y && my <= y + cards_cardHeight;
}

boolean cards_isMatched(int row, int col) {
  for (CardPos pos : cards_matchedCards) {
    if (pos.row == row && pos.col == col) {
      return true;
    }
  }
  return false;
}

boolean cards_isCurrentlyFlipped(int row, int col) {
  for (FlippedCard card : cards_flippedCards) {
    if (card.row == row && card.col == col) {
      return true;
    }
  }
  return false;
}

FlippingCard cards_getFlippingCard(int row, int col) {
  for (FlippingCard card : cards_flippingCards) {
    if (card.row == row && card.col == col) {
      return card;
    }
  }
  return null;
}

void cards_removeFromFlipped(int row, int col) {
  for (int i = cards_flippedCards.size() - 1; i >= 0; i--) {
    FlippedCard card = cards_flippedCards.get(i);
    if (card.row == row && card.col == col) {
      cards_flippedCards.remove(i);
      return;
    }
  }
}

void cards_initializeCardAssignments() {
  IntList indices = new IntList();
  for (int i = 0; i < cards_CARD_VARIANT_NAMES.length; i++) {
    indices.append(i);
    indices.append(i);
  }
  indices.shuffle();
  int idx = 0;
  for (int row = 0; row < cards_ROWS; row++) {
    for (int col = 0; col < cards_COLS; col++) {
      cards_cardAssignments[row][col] = indices.get(idx++);
    }
  }
}

float cards_bezierEase(float t) {
  if (t < 0.5f) {
    return 4 * t * t * t;
  } else {
    float u = -2 * t + 2;
    return 1 - (u * u * u) / 2f;
  }
}

void cards_playFlipSound() {
  if (cards_flipSound != null) {
    cards_flipSound.stop();
    cards_flipSound.play();
  }
}

void cards_playFanfare() {
  if (cards_fanfareSound != null) {
    cards_fanfareSound.stop();
    cards_fanfareSound.play();
  }
}

void cards_createConfetti(float x, float y) {
  int particleCount = 30;
  for (int i = 0; i < particleCount; i++) {
    cards_confettiParticles.add(new ConfettiParticle(x, y));
  }
}

void cleanupCards() {
  cards_initialized = false;
  cards_flippedCards.clear();
  cards_flippingCards.clear();
  cards_matchedCards.clear();
  cards_confettiParticles.clear();
  cards_resetHover();
}

// ============================================================================
// CARDS GAME CLASSES
// ============================================================================

class CardPos {
  int row;
  int col;
  CardPos(int row, int col) {
    this.row = row;
    this.col = col;
  }
}

class FlippedCard {
  int row;
  int col;
  int variantIndex;
  FlippedCard(int row, int col, int variantIndex) {
    this.row = row;
    this.col = col;
    this.variantIndex = variantIndex;
  }
}

class FlippingCard {
  int row;
  int col;
  float startTime;
  boolean isFlippingBack;
  FlippingCard(int row, int col, float startTime, boolean isFlippingBack) {
    this.row = row;
    this.col = col;
    this.startTime = startTime;
    this.isFlippingBack = isFlippingBack;
  }
}

class ConfettiParticle {
  float x;
  float y;
  float vx;
  float vy;
  float rotation;
  float rotationSpeed;
  float size;
  float life = 1.0f;
  float decay;
  int c;
  ConfettiParticle(float x, float y) {
    this.x = x;
    this.y = y;
    this.vx = random(-3, 3);
    this.vy = random(-8, -2);
    this.rotation = random(TWO_PI);
    this.rotationSpeed = random(-0.1f, 0.1f);
    this.size = random(4, 8);
    this.decay = random(0.01f, 0.02f);
    this.c = color(random(255), random(255), random(255), 200);
  }
  void update() {
    x += vx;
    y += vy;
    vy += 0.3f;
    rotation += rotationSpeed;
    life -= decay;
  }
  void draw(PGraphics pg) {
    pg.pushMatrix();
    pg.translate(x, y);
    pg.rotate(rotation);
    pg.noStroke();
    pg.fill(red(c), green(c), blue(c), life * 200);
    pg.rect(-size / 2f, -size / 2f, size, size);
    pg.popMatrix();
  }
  boolean isDead() {
    return life <= 0 || y > cards_viewHeight + 50;
  }
}
