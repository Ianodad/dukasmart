import React from "react";
import "./index.css";
import { Composition } from "remotion";
import { Deck, DECK_DURATION } from "./Deck";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="DukaSmartDeck"
      component={Deck}
      durationInFrames={DECK_DURATION}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
