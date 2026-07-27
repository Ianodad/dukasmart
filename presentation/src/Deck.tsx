import React from "react";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import {
  S1Title,
  S2Problem,
  S3What,
  S4Workflow,
  S5Money,
  S6Design,
  S7Built,
  S8Ai,
  S9Ocr,
  S10Close,
} from "./slides";

export const SLIDE_FRAMES = 135; // 4.5s per slide at 30fps
export const TRANSITION_FRAMES = 15;
const SLIDES = [S1Title, S2Problem, S3What, S4Workflow, S5Money, S6Design, S7Built, S8Ai, S9Ocr, S10Close];

export const DECK_DURATION =
  SLIDES.length * SLIDE_FRAMES - (SLIDES.length - 1) * TRANSITION_FRAMES;

export const Deck: React.FC = () => (
  <TransitionSeries>
    {SLIDES.flatMap((Slide, i) => {
      const seq = (
        <TransitionSeries.Sequence key={`s${i}`} durationInFrames={SLIDE_FRAMES}>
          <Slide />
        </TransitionSeries.Sequence>
      );
      if (i === SLIDES.length - 1) return [seq];
      return [
        seq,
        <TransitionSeries.Transition
          key={`t${i}`}
          presentation={fade()}
          timing={linearTiming({ durationInFrames: TRANSITION_FRAMES })}
        />,
      ];
    })}
  </TransitionSeries>
);
